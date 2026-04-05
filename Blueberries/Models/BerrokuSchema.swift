import Foundation
import SwiftData

// MARK: - Versioned schema

/// Version 1 of the Berroku persistent schema.
///
/// This is the first *explicitly versioned* schema. It intentionally matches
/// the shape of whatever shipped previously (as lightweight-migrated by
/// SwiftData), so the first run after introducing the migration plan is a
/// no-op: SwiftData sees the current store already matches `SchemaV1` and
/// doesn't need to do anything.
///
/// When the model shape changes in the future:
///   1. Copy `GameState` / `PlayerStats` into a namespaced enum `SchemaV2`,
///      apply the changes there, and add any new version identifier.
///   2. Append `SchemaV2.self` to `BerrokuMigrationPlan.schemas`.
///   3. Append a `MigrationStage` (usually `.lightweight`) describing the
///      transition from V1 to V2.
///
/// Always give new properties defaults so lightweight migration can populate
/// existing rows — that is the single most common cause of a failed
/// SwiftData migration.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [GameState.self, PlayerStats.self]
    }
}

// MARK: - Migration plan

/// Migration plan for Berroku's SwiftData store.
///
/// Each entry in `schemas` is a frozen snapshot of the model shape at that
/// version. Each entry in `stages` describes how SwiftData should get from
/// one version to the next. For a lightweight (automatic) migration — which
/// is sufficient as long as every new property has a default value or is
/// optional — use `.lightweight(fromVersion:toVersion:)`.
///
/// For anything non-trivial (renaming a property, splitting an attribute,
/// backfilling from another model) use `.custom` instead.
enum BerrokuMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        // No prior schema versions yet; future entries go here.
        []
    }
}
