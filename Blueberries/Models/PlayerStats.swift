// The `PlayerStats` model lives inside `SchemaV2` in BerrokuSchema.swift so
// each schema version can hold its own frozen snapshot for migrations. A
// top-level `typealias PlayerStats = SchemaV2.PlayerStats` (declared in
// BerrokuSchema.swift) lets the rest of the app keep using the short name.
