extends Node
## In-app purchases for puzzle packs and the Supporter (ad-free) upgrade.
##
## Entitlements come only from the purchase backend (the platform store). The local
## `entitlement_cache` in the save is written for diagnostics but is never read back as
## proof of purchase. With no billing plugin installed, nothing is owned and every buy
## attempt fails gracefully. Successful real-money purchases are never simulated.

const SUPPORTER_ID := "supporter"
const PRODUCTS := {
	"pack_overclock": {
		"title": "Overclock Pack",
		"description": "60 expert circuits: multi-branch routes, fixed tiles and tight move limits.",
	},
	"pack_logic_gates": {
		"title": "Logic Gates Pack",
		"description": "60 circuits built around the AND gate: wire both inputs before the signal can pass.",
	},
	"pack_circuit_breaker": {
		"title": "Circuit Breaker Pack",
		"description": "60 circuits built around broken wires and overloaded paths, routing power to multiple targets at once.",
	},
	"pack_quantum_protocol": {
		"title": "Quantum Protocol Pack",
		"description": "60 advanced circuits: splitters and relays synchronize multiple outputs, and every move counts.",
	},
	SUPPORTER_ID: {
		"title": "Supporter",
		"description": "6 hints a day instead of 3, no forced ad breaks, a bigger no-hint solve bonus, and one premium pack of your choice unlocked in full.",
	},
}

var backend: PurchaseBackend = PurchaseBackend.new()
## product_id -> localised price string, as reported by the store.
var prices: Dictionary = {}
var _owned: PackedStringArray = PackedStringArray()
var _busy := false


func _ready() -> void:
	set_backend(_detect_backend())


func set_backend(new_backend: PurchaseBackend) -> void:
	if backend != null and backend.owned_products_received.is_connected(_on_owned):
		backend.owned_products_received.disconnect(_on_owned)
		backend.products_received.disconnect(_on_products)
	backend = new_backend if new_backend != null else PurchaseBackend.new()
	backend.owned_products_received.connect(_on_owned)
	backend.products_received.connect(_on_products)
	_owned = PackedStringArray()
	prices.clear()
	if backend.is_available():
		backend.query_products(PackedStringArray(PRODUCTS.keys()))
		backend.query_owned()


func is_available() -> bool:
	return backend.is_available()


func is_busy() -> bool:
	return _busy


func owns(product_id: String) -> bool:
	return _owned.has(product_id)


func is_supporter() -> bool:
	return owns(SUPPORTER_ID)


func price_of(product_id: String) -> String:
	return str(prices.get(product_id, ""))


func product_info(product_id: String) -> Dictionary:
	return PRODUCTS.get(product_id, {"title": product_id, "description": ""})


## Starts a purchase. Await the result:
##   { "success": bool, "cancelled": bool, "message": String }
func purchase(product_id: String) -> Dictionary:
	if not PRODUCTS.has(product_id):
		return {"success": false, "cancelled": false, "message": "Unknown product."}
	if owns(product_id):
		return {"success": true, "cancelled": false, "message": "You already own this."}
	if not backend.is_available():
		return {"success": false, "cancelled": false, "message": "Purchases aren't available on this device right now."}
	if _busy:
		return {"success": false, "cancelled": false, "message": "Another purchase is in progress."}
	_busy = true
	var waiter := _Result.new()
	var on_success := func(id: String) -> void:
		if id == product_id:
			waiter.finish({"success": true, "cancelled": false, "message": "Thank you! %s is unlocked." % product_info(id)["title"]})
	var on_cancel := func(id: String) -> void:
		if id == product_id:
			waiter.finish({"success": false, "cancelled": true, "message": "Purchase cancelled. You were not charged."})
	var on_fail := func(id: String, message: String) -> void:
		if id == product_id:
			waiter.finish({"success": false, "cancelled": false, "message": "Purchase failed: %s" % message})
	backend.purchase_succeeded.connect(on_success)
	backend.purchase_cancelled.connect(on_cancel)
	backend.purchase_failed.connect(on_fail)
	backend.purchase(product_id)
	var outcome: Dictionary = await waiter.wait()
	backend.purchase_succeeded.disconnect(on_success)
	backend.purchase_cancelled.disconnect(on_cancel)
	backend.purchase_failed.disconnect(on_fail)
	if outcome["success"]:
		# The store confirmed the transaction; record it for this session and re-sync.
		_grant(product_id)
		backend.query_owned()
	_busy = false
	return outcome


## Re-reads ownership from the store. Await the result: { "restored": int, "message": String }
func restore_purchases() -> Dictionary:
	if not backend.is_available():
		return {"restored": 0, "message": "Purchases aren't available on this device right now."}
	var waiter := _Result.new()
	var on_owned := func(ids: PackedStringArray) -> void: waiter.finish({"ids": ids})
	var on_fail := func(message: String) -> void: waiter.finish({"error": message})
	backend.owned_products_received.connect(on_owned)
	backend.restore_failed.connect(on_fail)
	backend.restore()
	var result: Dictionary = await waiter.wait()
	backend.owned_products_received.disconnect(on_owned)
	backend.restore_failed.disconnect(on_fail)
	if result.has("error"):
		return {"restored": 0, "message": "Could not restore purchases: %s" % result["error"]}
	var count := 0
	for id: String in result["ids"]:
		if PRODUCTS.has(id):
			count += 1
	if count == 0:
		return {"restored": 0, "message": "No previous purchases were found for this account."}
	return {"restored": count, "message": "Restored %d purchase%s." % [count, "" if count == 1 else "s"]}


func _on_owned(ids: PackedStringArray) -> void:
	var owned := PackedStringArray()
	for id in ids:
		if PRODUCTS.has(id) and not owned.has(id):
			owned.append(id)
	_owned = owned
	_sync_cache()


func _on_products(products: Array) -> void:
	for product: Variant in products:
		if typeof(product) == TYPE_DICTIONARY and PRODUCTS.has(str(product.get("id", ""))):
			prices[str(product["id"])] = str(product.get("price", ""))
	SignalBus.entitlements_changed.emit()


func _grant(product_id: String) -> void:
	if not _owned.has(product_id):
		_owned.append(product_id)
	_sync_cache()


func _sync_cache() -> void:
	SaveService.progress.entitlement_cache = _owned.duplicate()
	SaveService.save_progress()
	SignalBus.entitlements_changed.emit()


## Picks a platform backend when a billing plugin is installed. See docs/PLUGIN_INTEGRATION.md.
## The adapter script path comes from the project setting `signal_shift/purchase_backend_script`
## (per platform via feature overrides, e.g. `signal_shift/purchase_backend_script.android`).
## Any failure falls back to the base backend, so a broken plugin never blocks play.
func _detect_backend() -> PurchaseBackend:
	var path: String = ProjectSettings.get_setting("signal_shift/purchase_backend_script", "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return PurchaseBackend.new()
	var script := load(path) as Script
	var instance: Variant = script.new() if script != null and script.can_instantiate() else null
	if instance is PurchaseBackend:
		return instance
	push_warning("%s is not a PurchaseBackend; using the no-SDK backend." % path)
	return PurchaseBackend.new()


class _Result:
	extends RefCounted
	signal done
	var _finished := false
	var _value: Dictionary = {}

	func finish(value: Dictionary) -> void:
		if _finished:
			return
		_finished = true
		_value = value
		done.emit()

	func wait() -> Dictionary:
		if not _finished:
			await done
		return _value
