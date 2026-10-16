class_name PurchaseBackend
extends RefCounted
## Interface between PurchaseService and a platform billing plugin (Google Play Billing,
## StoreKit). Concrete backends translate plugin callbacks into these signals.
## The base class is the "no billing" backend: unavailable, never reports a purchase.

## Each product: { "id": String, "title": String, "price": String (localised) }.
signal products_received(products: Array)
## Products the store reports as owned (after query or restore). Authoritative.
signal owned_products_received(product_ids: PackedStringArray)
signal purchase_succeeded(product_id: String)
signal purchase_cancelled(product_id: String)
signal purchase_failed(product_id: String, message: String)
signal restore_failed(message: String)


func is_available() -> bool:
	return false


func query_products(_product_ids: PackedStringArray) -> void:
	products_received.emit.call_deferred([])


## Asks the store which non-consumables the player owns.
func query_owned() -> void:
	owned_products_received.emit.call_deferred(PackedStringArray())


func purchase(product_id: String) -> void:
	purchase_failed.emit.call_deferred(product_id, "Billing is not available on this device.")


## Store-mandated restore flow (required on iOS). Results arrive via owned_products_received.
func restore() -> void:
	restore_failed.emit.call_deferred("Billing is not available on this device.")


func backend_name() -> String:
	return "none"
