import 'package:flutter/material.dart';

/// Shared composition used by the application and the review mockup.
/// All data, authorization, navigation and localized copy come from callers.
class NearbyStudioLayout extends StatelessWidget {
  const NearbyStudioLayout({
    required this.greeting,
    required this.subtitle,
    required this.meetups,
    required this.placesTitle,
    required this.city,
    required this.cityDetails,
    required this.listLabel,
    required this.mapLabel,
    required this.onCity,
    required this.onList,
    required this.onMap,
    required this.map,
    this.catalogStatus = const SizedBox.shrink(),
    super.key,
  });
  final String greeting, subtitle, placesTitle, city, cityDetails;
  final String listLabel, mapLabel;
  final Widget meetups, map, catalogStatus;
  final VoidCallback onCity, onList, onMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const Key('nearby-studio-scroll'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(greeting, style: theme.textTheme.headlineLarge),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            meetups,
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(placesTitle, style: theme.textTheme.headlineSmall),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final cityControl = OutlinedButton.icon(
                  key: const Key('choose-city'),
                  onPressed: onCity,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.location_on_outlined, size: 20),
                  label: Row(
                    children: [
                      Expanded(
                        child: Text(city, style: theme.textTheme.titleMedium),
                      ),
                      const Icon(Icons.expand_more, size: 20),
                    ],
                  ),
                );
                final listControl = FilledButton.icon(
                  key: const Key('nearby-places-list'),
                  onPressed: onList,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.format_list_bulleted, size: 18),
                  label: Text(listLabel),
                );
                if (MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                    constraints.maxWidth < 320) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      cityControl,
                      const SizedBox(height: 8),
                      listControl,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: cityControl),
                    const SizedBox(width: 8),
                    Expanded(child: listControl),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            catalogStatus,
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  map,
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton.filledTonal(
                      key: const Key('nearby-fullscreen-map'),
                      tooltip: mapLabel,
                      onPressed: onMap,
                      icon: const Icon(Icons.open_in_full, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One public meetup preview and a clear route to all meetups.
/// Supporting state feedback remains visible beside cached content.
class NearbyMeetupPreview extends StatelessWidget {
  const NearbyMeetupPreview({
    required this.title,
    required this.description,
    required this.allLabel,
    required this.onAll,
    this.state = const SizedBox.shrink(),
    this.secondaryAction,
    super.key,
  });
  final String title, description, allLabel;
  final VoidCallback onAll;
  final Widget state;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
          ],
          state,
          const SizedBox(height: 8),
          InkWell(
            key: const Key('nearby-all-meetups'),
            onTap: onAll,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(child: Text(allLabel)),
                  const SizedBox(width: 12),
                  const ExcludeSemantics(
                    child: Icon(Icons.arrow_forward, size: 20),
                  ),
                ],
              ),
            ),
          ),
          ?secondaryAction,
        ],
      ),
    ),
  );
}

/// The current native header is retained during the screen-by-screen rollout.
/// Role capability and mode switching remain owned by the application shell.
class NearbyStudioHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const NearbyStudioHeader({
    required this.dark,
    required this.themeLabel,
    required this.onTheme,
    this.modeControl,
    this.fallbackBadge,
    this.notificationAction,
    this.settingsAction,
    this.stacked = false,
    this.tall = false,
    super.key,
  });
  final bool dark, stacked, tall;
  final String themeLabel;
  final VoidCallback onTheme;
  final Widget? modeControl, fallbackBadge, notificationAction, settingsAction;

  @override
  Size get preferredSize => Size.fromHeight(
    (tall ? 104 : 60) + (stacked && modeControl != null ? 64 : 0),
  );
  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: tall ? 104 : 60,
    titleSpacing: 20,
    title: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'petfriendly',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -1,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            '.',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: dark ? const Color(0xFFD6ED8A) : const Color(0xFF587322),
            ),
          ),
        ],
      ),
    ),
    bottom: stacked && modeControl != null
        ? PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: modeControl!,
              ),
            ),
          )
        : null,
    actions: [
      if (!stacked && modeControl != null) modeControl!,
      if (modeControl == null && fallbackBadge != null) fallbackBadge!,
      ?notificationAction,
      IconButton(
        tooltip: themeLabel,
        onPressed: onTheme,
        icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      ),
      ?settingsAction,
      const SizedBox(width: 10),
    ],
  );
}

class NearbyMeetupFeedback extends StatelessWidget {
  const NearbyMeetupFeedback({
    required this.loading,
    required this.loadingLabel,
    required this.retryLabel,
    this.errorLabel,
    this.onRetry,
    super.key,
  });
  final bool loading;
  final String loadingLabel, retryLabel;
  final String? errorLabel;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loading) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(semanticsLabel: loadingLabel),
        ],
        if (errorLabel != null)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                errorLabel!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ),
      ],
    ),
  );
}
