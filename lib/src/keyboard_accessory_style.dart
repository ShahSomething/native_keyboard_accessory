import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// Which buttons the bar shows.
enum KeyboardAccessoryLayout {
  /// Chevrons on the leading edge, done on the trailing edge. Mirrors itself
  /// in a right-to-left locale.
  navigationAndDone,

  /// Done only. The right choice when fields are not part of a traversable
  /// form, so the chevrons would have nowhere to go.
  doneOnly,

  /// Chevrons only, with no dismiss button.
  navigationOnly;
}

/// How the bar looks.
///
/// Colors are sent to UIKit as a pair and resolved per trait collection, so one
/// [KeyboardAccessoryStyle] covers light and dark mode. Supplying only the light
/// value uses it for both, which is the right choice for an app that pins a
/// single appearance.
@immutable
class KeyboardAccessoryStyle {
  /// Creates a style. Every value has a default, so `const
  /// KeyboardAccessoryStyle()` is a usable starting point.
  const KeyboardAccessoryStyle({
    this.backgroundColor,
    this.darkBackgroundColor,
    this.tintColor,
    this.darkTintColor,
    this.height = 56,
    this.horizontalInset = 16,
    this.verticalInset = 6,
    this.cornerRadius = 22,
    this.continuousCorners = true,
    this.shadowOpacity = 0.12,
    this.layout = KeyboardAccessoryLayout.navigationAndDone,
  });

  /// Pill fill in light mode. Null leaves the pill unfilled, letting the app's
  /// own background show through.
  final Color? backgroundColor;

  /// Pill fill in dark mode. Falls back to [backgroundColor].
  final Color? darkBackgroundColor;

  /// Icon color in light mode. Defaults to `UIColor.labelColor`.
  final Color? tintColor;

  /// Icon color in dark mode. Falls back to [tintColor].
  final Color? darkTintColor;

  /// Total accessory height in points, pill plus [verticalInset] either side.
  ///
  /// iOS reports the keyboard frame including the accessory view, so this is
  /// automatically part of `MediaQuery.viewInsets.bottom` — Flutter scrolls
  /// content clear of the bar with no extra work.
  final double height;

  /// Gap between the pill and the screen edges. The app's background shows
  /// through here.
  final double horizontalInset;

  /// Gap above and below the pill.
  final double verticalInset;

  /// Pill corner radius in points.
  final double cornerRadius;

  /// Uses `kCACornerCurveContinuous`, the squircle curvature iOS itself uses
  /// and the UIKit equivalent of a `figma_squircle` smoothing of 1. Set false
  /// for a plain circular radius.
  final bool continuousCorners;

  /// 0 disables the pill's drop shadow.
  final double shadowOpacity;

  /// Which buttons the bar shows.
  final KeyboardAccessoryLayout layout;

  /// Serializes this style for the method channel. Colors that were not
  /// supplied are omitted rather than sent as null, so the platform side can
  /// tell "unset" from "transparent".
  Map<String, Object?> toMap() => <String, Object?>{
        if (backgroundColor != null)
          'backgroundColor': backgroundColor!.toARGB32(),
        if (darkBackgroundColor != null)
          'darkBackgroundColor': darkBackgroundColor!.toARGB32(),
        if (tintColor != null) 'tintColor': tintColor!.toARGB32(),
        if (darkTintColor != null) 'darkTintColor': darkTintColor!.toARGB32(),
        'height': height,
        'horizontalInset': horizontalInset,
        'verticalInset': verticalInset,
        'cornerRadius': cornerRadius,
        'continuousCorners': continuousCorners,
        'shadowOpacity': shadowOpacity,
        'layout': layout.index,
      };

  @override
  bool operator ==(Object other) =>
      other is KeyboardAccessoryStyle &&
      other.backgroundColor == backgroundColor &&
      other.darkBackgroundColor == darkBackgroundColor &&
      other.tintColor == tintColor &&
      other.darkTintColor == darkTintColor &&
      other.height == height &&
      other.horizontalInset == horizontalInset &&
      other.verticalInset == verticalInset &&
      other.cornerRadius == cornerRadius &&
      other.continuousCorners == continuousCorners &&
      other.shadowOpacity == shadowOpacity &&
      other.layout == layout;

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        darkBackgroundColor,
        tintColor,
        darkTintColor,
        height,
        horizontalInset,
        verticalInset,
        cornerRadius,
        continuousCorners,
        shadowOpacity,
        layout,
      );
}
