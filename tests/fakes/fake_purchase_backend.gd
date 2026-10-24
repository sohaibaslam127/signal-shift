extends PurchaseBackend
## Test double for the store. Only used by tests; the game never ships a simulated store.

var mode := "success" # "success", "cancel", "fail"
var store_owned := PackedStringArray()


func is_available() -> bool:
	return true


func query_products(product_ids: PackedStringArray) -> void:
	var products := []
	for id in product_ids:
		products.append({"id": id, "title": id, "price": "$1.99"})
	products_received.emit.call_deferred(products)


func query_owned() -> void:
	owned_products_received.emit.call_deferred(store_owned.duplicate())


func purchase(product_id: String) -> void:
	match mode:
		"success":
			store_owned.append(product_id)
			purchase_succeeded.emit.call_deferred(product_id)
		"cancel":
			purchase_cancelled.emit.call_deferred(product_id)
		_:
			purchase_failed.emit.call_deferred(product_id, "card declined")


func restore() -> void:
	owned_products_received.emit.call_deferred(store_owned.duplicate())
