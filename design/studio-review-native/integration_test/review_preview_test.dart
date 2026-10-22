import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:studio_review/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Complete Studio design preview captures and journeys', (
    tester,
  ) async {
    await tester.pumpWidget(const ReviewApp());
    await tester.pumpAndSettle();
    final s = tester.state<ReviewAppState>(find.byType(ReviewApp));
    Future<void> capture(String name) async {
      await tester.pump(const Duration(milliseconds: 300));
      await binding.takeScreenshot(name);
    }

    for (final dark in [false, true]) {
      final suffix = dark ? 'dark' : 'light';
      for (final page in [
        'nearby',
        'places',
        'social',
        'requests',
        'walks',
        'profile',
        'conditions',
        'roles',
        'chats',
        'chat',
      ]) {
        s.captureState(
          page,
          isHelper: ['requests', 'conditions', 'chats', 'chat'].contains(page),
          isDark: dark,
        );
        await tester.pumpAndSettle();
        await capture('$page-$suffix');
      }
      for (final tab in ['history', 'reviews']) {
        s.tab = tab;
        s.captureState('walks', isDark: dark);
        await tester.pumpAndSettle();
        await capture('$tab-$suffix');
      }
      s.tab = 'reviews';
      s.captureState('walks', state: 'empty', isDark: dark);
      await tester.pumpAndSettle();
      await capture('reviews-empty-$suffix');
      for (final social in ['communities', 'meetups']) {
        s.social = social;
        s.captureState('social', isDark: dark);
        await tester.pumpAndSettle();
        await capture('$social-$suffix');
      }
      s.captureState('profile', isHelper: true, isDark: dark);
      await tester.pumpAndSettle();
      await capture('helper-profile-$suffix');
      for (final state in ['empty', 'error', 'loading']) {
        s.captureState('requests', state: state, isHelper: true, isDark: dark);
        await tester.pump(const Duration(milliseconds: 300));
        await capture('requests-$state-$suffix');
      }
      s.captureState('requests', isHelper: true, isDark: dark);
      await tester.pumpAndSettle();
      s.filters('requests');
      await tester.pumpAndSettle();
      await capture('filters-$suffix');
      Navigator.pop(s.currentContext!);
      await tester.pumpAndSettle();
      s.periodSheet();
      await tester.pumpAndSettle();
      await capture('period-$suffix');
      Navigator.pop(s.currentContext!);
      await tester.pumpAndSettle();
      s.howItWorks();
      await tester.pumpAndSettle();
      await capture('help-$suffix');
      Navigator.pop(s.currentContext!);
      await tester.pumpAndSettle();
      s.captureState('chat', isDark: dark);
      await tester.pumpAndSettle();
      s.detailsSheet();
      await tester.pumpAndSettle();
      await capture('details-$suffix');
      Navigator.pop(s.currentContext!);
      await tester.pumpAndSettle();
      s.reviewSheet();
      await tester.pumpAndSettle();
      await capture('review-sheet-$suffix');
      Navigator.pop(s.currentContext!);
      await tester.pumpAndSettle();
    }
    // Actual Back paths and drafts.
    s.captureState('social');
    s.communityJoined = true;
    s.go('community');
    await tester.pumpAndSettle();
    s.go('community-chat');
    await tester.pumpAndSettle();
    s.back();
    expect(s.page, 'community');
    s.back();
    expect(s.page, 'social');
    s.go('meetup');
    s.go('meetup-chat');
    s.back();
    expect(s.page, 'meetup');
    s.back();
    expect(s.page, 'social');
    s.captureState('walks');
    s.go('chat');
    s.message.text = 'Сохранённый черновик';
    s.back();
    s.go('chat');
    expect(s.message.text, 'Сохранённый черновик');
    s.captureState('chat', isHelper: true);
    s.walkState = 'selected';
    await tester.pumpAndSettle();
    await tester.tap(find.text('Начать прогулку'));
    await tester.pumpAndSettle();
    expect(s.walkState, 'progress');
    await tester.tap(find.text('Завершить прогулку'));
    await tester.pumpAndSettle();
    expect(s.walkState, 'waiting');
    s.captureState('chat');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Подтвердить завершение'));
    await tester.pumpAndSettle();
    expect(s.walkState, 'completed');
    await capture('chat-completed-light');
    s.reviewSheet();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('5 / 5'));
    await tester.enterText(find.byType(TextField).last, 'Спасибо за прогулку');
    s.failSave = true;
    await tester.ensureVisible(find.text('Опубликовать отзыв'));
    await tester.tap(find.text('Опубликовать отзыв'));
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(s.review.text, 'Спасибо за прогулку');
    await capture('review-error-input-light');
    s.failSave = false;
    await tester.ensureVisible(find.text('Опубликовать отзыв'));
    await tester.tap(find.text('Опубликовать отзыв'));
    await tester.pumpAndSettle();
    expect(s.reviewed, true);
    for (final language in ['en', 'be', 'pl']) {
      s.tab = 'reviews';
      s.captureState('walks', language: language);
      await tester.pumpAndSettle();
      await capture('reviews-$language-light');
    }
    s.captureState('requests', isHelper: true, textScale: 2, language: 'pl');
    await tester.pumpAndSettle();
    await capture('requests-pl-200-light');
    s.filters('requests');
    await tester.pumpAndSettle();
    await capture('filters-pl-200-light');
    Navigator.pop(s.currentContext!);
    await tester.pumpAndSettle();
    s.captureState('chat', textScale: 1, language: 'en');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Draft while typing');
    await tester.pumpAndSettle();
    await capture('chat-keyboard-en-light');
  });
}
