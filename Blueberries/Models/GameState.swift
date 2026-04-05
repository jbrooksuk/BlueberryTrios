// The `GameState` model lives inside `SchemaV2` in BerrokuSchema.swift so
// each schema version can hold its own frozen snapshot for migrations. A
// top-level `typealias GameState = SchemaV2.GameState` (declared in
// BerrokuSchema.swift) lets the rest of the app keep using the short name.
