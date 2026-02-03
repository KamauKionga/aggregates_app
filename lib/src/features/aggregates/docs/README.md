# Aggregates & Pricing

Features implemented:
- Product list (Dust, 1/4", 1/2", 3/4", 1", Ballast)
- Pricing repository (Firestore)
- Default price: 1100 Ksh/ton
- Admin pricing UI (editable prices) — `AdminPricingScreen`
- Quarry role: view-only (UI disables editing for non-admin/quarry)
- Validation helpers: 14-ton trucks only; orders for 1 or 2 trucks only

Data:
- Pricing stored in `aggregates_pricing/{productId}` documents with fields `pricePerTon` and `updatedAt`.

Notes:
- For now admin users can edit prices via the UI; you can restrict further by enforcing Firestore rules to only allow writes by admin custom claim.
- Orders use `AggregatesValidator` to compute tons and total price.
