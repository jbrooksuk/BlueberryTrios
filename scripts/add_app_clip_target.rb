#!/usr/bin/env ruby
# Adds the BerrokuClip App Clip target to Blueberries.xcodeproj.
# Idempotent: re-running after a successful add is a no-op.
# Run from repo root with: ruby scripts/add_app_clip_target.rb

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../../Blueberries.xcodeproj', __FILE__)
CLIP_TARGET_NAME = 'BerrokuClip'
CLIP_FOLDER_NAME = 'BlueberriesClip'
CLIP_PRODUCT_NAME = 'BerrokuClip'
MAIN_TARGET_NAME = 'Blueberries'
MAIN_SYNC_FOLDER_NAME = 'Blueberries'
DEVELOPMENT_TEAM = '94MWDYL76Q'
APP_CLIP_BUNDLE_ID_RELEASE = 'com.altthree.Berroku.Clip'
APP_CLIP_BUNDLE_ID_DEBUG = 'com.altthree.Berroku.debug.Clip'

# Files from the main Blueberries/ folder that should NOT be compiled/copied into
# the App Clip target. Add new exclusions here when you add files that should
# stay main-app-only (SwiftData models, main-app views, services that pull in
# StoreKit / GameKit / SwiftData, localisation, etc.).
MAIN_FOLDER_EXCLUSIONS_FOR_CLIP = [
  # Top-level main-app-only artefacts.
  'Blueberries.entitlements',
  'BlueberriesApp.swift',
  'Info.plist',
  'Localizable.xcstrings',
  'Products.storekit',

  # SwiftData persistence — the clip has no store.
  'Models/BerrokuSchema.swift',
  'Models/GameState.swift',
  'Models/PlayerStats.swift',

  # Services the clip doesn't use.
  'Services/GameCenterService.swift',
  'Services/NotificationService.swift',
  'Services/PuzzleSolver.swift',
  'Services/StoreKitService.swift',

  # Main-app UI.
  'Views/BerryClusterView.swift',
  'Views/BlueberryView.swift',
  'Views/CalendarView.swift',
  'Views/ConfettiView.swift',
  'Views/GameView.swift',
  'Views/HomeView.swift',
  'Views/IllustratedBerryClusterView.swift',
  'Views/LeafView.swift',
  'Views/SettingsFormView.swift',
  'Views/ShareCardView.swift',
  'Views/TutorialView.swift',
  'Views/WalkthroughView.swift'
].freeze

# Files from BlueberriesClip/ that are not compiled (Info.plist, entitlements).
CLIP_FOLDER_EXCLUSIONS = [
  'Info.plist',
  'BerrokuClip.entitlements',
  'BerrokuClip.Debug.entitlements'
].freeze

project = Xcodeproj::Project.open(PROJECT_PATH)

if project.native_targets.any? { |t| t.name == CLIP_TARGET_NAME }
  puts "Target #{CLIP_TARGET_NAME} already exists — nothing to do."
  exit 0
end

main_target = project.native_targets.find { |t| t.name == MAIN_TARGET_NAME }
raise "Main target #{MAIN_TARGET_NAME} not found" unless main_target

# Existing Blueberries synchronized root group — we'll share it with the clip.
main_sync_group = project.main_group.children.find do |c|
  c.is_a?(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup) &&
    c.display_name == MAIN_SYNC_FOLDER_NAME
end
raise "Synchronized group '#{MAIN_SYNC_FOLDER_NAME}' not found" unless main_sync_group

# --- 1. Create the clip target (as a plain app, then coerce to App Clip). ---
clip_target = project.new_target(
  :application,
  CLIP_TARGET_NAME,
  :ios,
  '17.0',
  project.products_group,
  :swift
)
clip_target.product_type = 'com.apple.product-type.application.on-demand-install-capable'

clip_product = clip_target.product_reference
clip_product.path = "#{CLIP_PRODUCT_NAME}.app"
clip_product.name = "#{CLIP_PRODUCT_NAME}.app"
clip_product.explicit_file_type = 'wrapper.application'

# --- 2. Build settings per configuration. ---
base_settings = {
  'ASSETCATALOG_COMPILER_APPICON_NAME' => 'AppIcon',
  'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME' => 'AccentColor',
  'CODE_SIGN_STYLE' => 'Automatic',
  'CURRENT_PROJECT_VERSION' => '1',
  'DEVELOPMENT_TEAM' => DEVELOPMENT_TEAM,
  'ENABLE_PREVIEWS' => 'YES',
  'GENERATE_INFOPLIST_FILE' => 'YES',
  'INFOPLIST_FILE' => 'BlueberriesClip/Info.plist',
  'INFOPLIST_KEY_LSApplicationCategoryType' => 'public.app-category.puzzle-games',
  'INFOPLIST_KEY_NSHumanReadableCopyright' => '',
  'INFOPLIST_KEY_UIApplicationSceneManifest_Generation' => 'YES',
  'INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents' => 'YES',
  'INFOPLIST_KEY_UILaunchScreen_Generation' => 'YES',
  'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone' => 'UIInterfaceOrientationPortrait',
  'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad' =>
    'UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight',
  'LD_RUNPATH_SEARCH_PATHS' => ['$(inherited)', '@executable_path/Frameworks'],
  'MARKETING_VERSION' => '1.6',
  'PRODUCT_NAME' => '$(TARGET_NAME)',
  'STRING_CATALOG_GENERATE_SYMBOLS' => 'YES',
  'SUPPORTED_PLATFORMS' => 'iphoneos iphonesimulator',
  'SUPPORTS_MACCATALYST' => 'NO',
  'SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD' => 'NO',
  'SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD' => 'NO',
  'SWIFT_APPROACHABLE_CONCURRENCY' => 'YES',
  'SWIFT_DEFAULT_ACTOR_ISOLATION' => 'MainActor',
  'SWIFT_EMIT_LOC_STRINGS' => 'YES',
  'SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY' => 'YES',
  'SWIFT_VERSION' => '5.0',
  'TARGETED_DEVICE_FAMILY' => '1,2'
}.freeze

clip_target.build_configurations.each do |config|
  settings = base_settings.dup
  if config.name == 'Debug'
    # Each entitlements file declares a single parent app identifier
    # (Apple rejects multiple), so debug + release point at separate files.
    settings['CODE_SIGN_ENTITLEMENTS'] = 'BlueberriesClip/BerrokuClip.Debug.entitlements'
    settings['PRODUCT_BUNDLE_IDENTIFIER'] = APP_CLIP_BUNDLE_ID_DEBUG
    settings['INFOPLIST_KEY_CFBundleDisplayName'] = 'Berroku Clip Debug'
    settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon-Debug'
  else
    settings['CODE_SIGN_ENTITLEMENTS'] = 'BlueberriesClip/BerrokuClip.entitlements'
    settings['PRODUCT_BUNDLE_IDENTIFIER'] = APP_CLIP_BUNDLE_ID_RELEASE
    settings['INFOPLIST_KEY_CFBundleDisplayName'] = 'Berroku Clip'
  end
  config.build_settings = settings
end

# --- 3. Create a synchronized root group for BlueberriesClip/. ---
clip_sync_group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
clip_sync_group.source_tree = '<group>'
clip_sync_group.path = CLIP_FOLDER_NAME
project.main_group << clip_sync_group

# Exception for the clip's own sync group: don't compile Info.plist or the entitlements file.
clip_own_exception = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedBuildFileExceptionSet)
clip_own_exception.target = clip_target
clip_own_exception.membership_exceptions = CLIP_FOLDER_EXCLUSIONS.dup
clip_sync_group.exceptions << clip_own_exception

clip_target.file_system_synchronized_groups << clip_sync_group

# --- 4. Share the main Blueberries/ sync group with the clip target via exceptions. ---
shared_exception = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedBuildFileExceptionSet)
shared_exception.target = clip_target
shared_exception.membership_exceptions = MAIN_FOLDER_EXCLUSIONS_FOR_CLIP.dup
main_sync_group.exceptions << shared_exception

clip_target.file_system_synchronized_groups << main_sync_group

# --- 5. Embed the clip's .app into the parent app's AppClips folder. ---
embed_phase_name = 'Embed App Clips'
embed_phase = main_target.copy_files_build_phases.find { |p| p.name == embed_phase_name }
unless embed_phase
  embed_phase = main_target.new_copy_files_build_phase(embed_phase_name)
  embed_phase.dst_subfolder_spec = '16' # Products Directory
  embed_phase.dst_path = '$(CONTENTS_FOLDER_PATH)/AppClips'
end
embed_build_file = embed_phase.add_file_reference(clip_product, true)
embed_build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

# --- 6. Main app depends on the clip so it builds first. ---
unless main_target.dependencies.any? { |d| d.target == clip_target }
  main_target.add_dependency(clip_target)
end

project.save

puts "Added #{CLIP_TARGET_NAME} target."
puts "Main-folder exclusions for clip: #{MAIN_FOLDER_EXCLUSIONS_FOR_CLIP.size} entries."
