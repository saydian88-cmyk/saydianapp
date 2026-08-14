package dev.flutter.plugins.integration_test;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;

/**
 * Release-only no-op used while Flutter incorrectly writes dev-only plugins to
 * GeneratedPluginRegistrant. Debug and integration-test builds continue to use
 * Flutter's real IntegrationTestPlugin.
 *
 * See: https://github.com/flutter/flutter/issues/169336
 */
public final class IntegrationTestPlugin implements FlutterPlugin {
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {}

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {}
}
