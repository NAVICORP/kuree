import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../core/kuri.dart';
import '../core/messages.dart';
import '../l10n/strings.dart';
import 'sign_in.dart';
import 'theme.dart';
import 'widgets.dart';

// ---------------------------------------------------------------- draw the rest

/// Every slot still to take the pot, shuffled over the months from next month
/// on. A slot is drawn as a whole, so a shared slot is one draw and a person
/// with two slots has two. Returns month -> slot when the admin uses the order.
Future<Map<int, int>?> showDrawRestSheet(BuildContext context, KuriDoc doc, int currentMonth) {
  final s = S.of(context);
  final slots = doc.waitingSlots();
  final months = [for (final m in doc.months) if (m.n > currentMonth && m.winner == null) m.n];
  if (months.isEmpty || slots.isEmpty) {
    toast(context, months.isEmpty ? s.everyMonthTaken : s.allSlotsTaken, bad: true);
    return Future.value(null);
  }
  var order = shuffled(slots);
  return showKSheet<Map<int, int>>(
    context,
    title: s.drawRest,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      final extra = order.length > months.length ? order.sublist(months.length) : <int>[];
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          months.length == 1
              ? s.drawRestIntroOne(slots.length, doc.monthLabel(months.first))
              : s.drawRestIntro(slots.length, months.length, doc.monthLabel(months.first)),
          style: T.small,
        ),
        const SizedBox(height: Sp.md + 2),
        for (var i = 0; i < months.length; i++)
          TweenAnimationBuilder<double>(
            key: ValueKey('${order.join(',')}-$i'),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 260 + i * 40),
            curve: Curves.easeOutCubic,
            builder: (_, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, (1 - t) * 10), child: child)),
            child: Container(
              margin: const EdgeInsets.only(bottom: Sp.sm),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: K.surface, borderRadius: BorderRadius.circular(K.rMd), border: Border.all(color: K.border)),
              child: Row(children: [
                Expanded(
                  flex: 5,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.monthN(months[i]), maxLines: 1, overflow: TextOverflow.ellipsis, style: T.bodyStrong),
                    Text(doc.monthLabel(months[i]), maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small),
                  ]),
                ),
                const SizedBox(width: Sp.sm),
                if (i < order.length) ...[
                  SlotBadge('${order[i]}', size: 36, style: SlotBadgeStyle.sun),
                  const SizedBox(width: Sp.md - 2),
                  Expanded(
                    flex: 7,
                    child: Text(doc.slotName(order[i]), maxLines: 2, overflow: TextOverflow.ellipsis, style: T.bodyStrong),
                  ),
                ] else
                  Expanded(flex: 7, child: Text(s.noSlotLeft, style: T.small)),
              ]),
            ),
          ),
        if (extra.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Sp.xs),
            child: Text(s.notPlaced(extra.map((x) => '$x. ${doc.slotName(x)}').join(', ')), style: T.small),
          ),
        const SizedBox(height: Sp.md),
        // One above the other, so neither label is cut short.
        KButton(
          label: s.useThisOrder,
          icon: Icons.check_rounded,
          expand: true,
          onPressed: () async {
            final ok = await confirm(ctx, title: s.useOrderTitle, text: s.useOrderText(months.length), yes: s.useIt);
            if (!ok || !ctx.mounted) return;
            Navigator.of(ctx).pop({for (var i = 0; i < months.length && i < order.length; i++) months[i]: order[i]});
          },
        ),
        const SizedBox(height: Sp.sm + 2),
        KButton(
          label: s.shuffleAgain,
          icon: Icons.shuffle_rounded,
          kind: KButtonKind.secondary,
          expand: true,
          onPressed: () {
            HapticFeedback.mediumImpact();
            setState(() => order = shuffled(slots));
          },
        ),
      ]);
    }),
  );
}

// ---------------------------------------------------------------- reminders

/// The whole list for the group in one tap, or each person on their own,
/// ticked off as they are sent.
Future<void> showRemindersSheet(BuildContext context, KuriDoc doc, Month m, String token,
    {required Future<void> Function(Person) onAddNumber}) {
  final s = S.of(context);
  final sent = <String>{};
  return showKSheet<void>(
    context,
    title: s.remindersTitle(m.n),
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      final dues = doc.dues(m);
      final withNo = dues.where((d) => d.person.phone.isNotEmpty).length;
      final missing = dues.length - withNo;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        KButton(
          label: s.shareListInGroup,
          icon: Icons.groups_rounded,
          expand: true,
          onPressed: () => _open(ctx, whatsApp(groupList(doc, m, token))),
        ),
        const SizedBox(height: Sp.md),
        Text(
          dues.isEmpty
              ? s.nobodyToRemind
              : s.remindEach(missing == 0 ? s.everyoneHasNumber : (missing == 1 ? s.noNumberOne : s.noNumberMany(missing))),
          style: T.small,
        ),
        const SizedBox(height: Sp.md),
        for (final d in dues)
          Container(
            margin: const EdgeInsets.only(bottom: Sp.sm),
            padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 10, 10),
            decoration: BoxDecoration(
              color: sent.contains(d.person.id) ? K.brand100 : K.surface,
              borderRadius: BorderRadius.circular(K.rMd),
              border: Border.all(color: K.border),
            ),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: K.surface2, shape: BoxShape.circle, border: Border.all(color: K.border)),
                child: Text(initials(d.person.name), style: T.label.copyWith(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: Sp.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.person.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.bodyStrong),
                  Text(
                    d.person.phone.isEmpty ? s.noNumberYet : s.dueMonth(doc.money(d.amount), m.n),
                    style: T.small.copyWith(color: d.person.phone.isEmpty ? K.warn : K.muted),
                  ),
                ]),
              ),
              const SizedBox(width: Sp.sm),
              // Capped, so a long label shrinks instead of squeezing the name.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: d.person.phone.isEmpty
                    ? KButton(
                        label: s.addNumber,
                        icon: Icons.phone_outlined,
                        kind: KButtonKind.secondary,
                        small: true,
                        onPressed: () async {
                          await onAddNumber(d.person);
                          setState(() {});
                        },
                      )
                    : KButton(
                        label: sent.contains(d.person.id) ? s.sent : s.remind,
                        icon: sent.contains(d.person.id) ? Icons.check_rounded : Icons.chat_outlined,
                        kind: sent.contains(d.person.id) ? KButtonKind.ghost : KButtonKind.primary,
                        small: true,
                        onPressed: () {
                          setState(() => sent.add(d.person.id));
                          _open(ctx, whatsApp(reminderFor(doc, m, d), phone: d.person.phone));
                        },
                      ),
              ),
            ]),
          ),
      ]);
    }),
  );
}

Future<void> _open(BuildContext context, Uri uri) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) toast(context, S.of(context).couldNotOpenWa, bad: true);
}

/// Asks for one person's WhatsApp number.
Future<String?> askPhone(BuildContext context, String name, String current) {
  final s = S.of(context);
  var cc = '91';
  final c = TextEditingController(text: current.isEmpty ? '' : prettyPhone(current));
  String? error;
  return showKSheet<String>(
    context,
    title: s.numberTitle(name),
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      void done() {
        final p = c.text.trim().startsWith('+') ? phoneDigits(c.text) : fullPhone(cc, c.text);
        if (p.isEmpty || p.length < 8) {
          setState(() => error = s.enterWaNumber);
          return;
        }
        Navigator.of(ctx).pop(p);
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (error != null) ...[Notice(error!), const SizedBox(height: Sp.md)],
        // Phone numbers read left to right in every language.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: [
            CountryButton(code: cc, onChanged: (v) => setState(() => cc = v)),
            const SizedBox(width: Sp.sm),
            Expanded(
              child: TextField(
                controller: c,
                autofocus: true,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                style: T.bodyStrong,
                decoration: InputDecoration(hintText: s.waNumberHint),
                onSubmitted: (_) => done(),
              ),
            ),
          ]),
        ),
        const SizedBox(height: Sp.sm),
        Text(s.numberUse, style: T.small),
        const SizedBox(height: Sp.lg),
        KButton(label: s.saveNumber, icon: Icons.check_rounded, expand: true, onPressed: done),
      ]);
    }),
  );
}

// ---------------------------------------------------------------- a month, as a calendar

/// A year of months to tap, with arrows to the years either side. Months
/// before [first] or after [last] can't be picked. Returns year * 100 + month.
Future<int?> pickMonth(BuildContext context,
    {required String title, required int year, required int month, required DateTime first, required DateTime last}) {
  final s = S.of(context);
  final now = DateTime.now();
  int key(int y, int m) => y * 100 + m;
  final lo = key(first.year, first.month), hi = key(last.year, last.month);
  var shown = year;
  return showKSheet<int>(
    context,
    title: title,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      Widget cell(int m) {
        final k = key(shown, m);
        final on = shown == year && m == month;
        final today = shown == now.year && m == now.month;
        final ok = k >= lo && k <= hi;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Sp.xs),
            child: Semantics(
              button: true,
              selected: on,
              enabled: ok,
              label: '${monthName(m)} $shown',
              child: Opacity(
                opacity: ok ? 1 : 0.35,
                child: Material(
                  color: on ? K.deep : (today ? K.brand100 : K.surface),
                  shape: StadiumBorder(side: BorderSide(color: on ? K.deep : (today ? K.brand300 : K.border))),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: ok ? () => Navigator.of(ctx).pop(k) : null,
                    child: SizedBox(
                      height: 46,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Sp.sm),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(monthShortName(m), maxLines: 1, style: T.bodyStrong.copyWith(color: on ? Colors.white : K.ink)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          RoundIcon(Icons.chevron_left_rounded, tooltip: s.prevYear, onTap: shown > first.year ? () => setState(() => shown--) : null),
          Expanded(child: Text('$shown', textAlign: TextAlign.center, style: T.h2.merge(T.tabular))),
          RoundIcon(Icons.chevron_right_rounded, tooltip: s.nextYear, onTap: shown < last.year ? () => setState(() => shown++) : null),
        ]),
        const SizedBox(height: Sp.md),
        for (var r = 0; r < 4; r++) Row(children: [for (var c = 1; c <= 3; c++) cell(r * 3 + c)]),
      ]);
    }),
  );
}

// ---------------------------------------------------------------- a day of the month, as a calendar

/// The days 1 to 31 in rows of seven, like a calendar page. Returns the day
/// tapped. 29, 30 and 31 fall back to the last day in shorter months.
Future<int?> pickDay(BuildContext context, {required String title, required int selected}) {
  final s = S.of(context);
  return showKSheet<int>(
    context,
    title: title,
    builder: (ctx) {
      Widget cell(int d) {
        if (d > 31) return const Expanded(child: SizedBox(height: 40));
        final on = d == selected;
        return Expanded(
          child: Center(
            child: Semantics(
              button: true,
              selected: on,
              label: dayOf(d),
              child: Material(
                color: on ? K.deep : K.surface,
                shape: CircleBorder(side: BorderSide(color: on ? K.deep : K.border)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(ctx).pop(d),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Text('$d', style: T.bodyStrong.merge(T.tabular).copyWith(color: on ? Colors.white : (d > 28 ? K.muted : K.ink))),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var r = 0; r < 5; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: Sp.sm),
            child: Row(children: [for (var c = 1; c <= 7; c++) cell(r * 7 + c)]),
          ),
        const SizedBox(height: Sp.xs),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 1), child: Icon(Icons.info_outline_rounded, size: 16, color: K.muted)),
          const SizedBox(width: Sp.sm),
          Expanded(child: Text('29, 30, 31: ${s.shorterMonths}', style: T.small)),
        ]),
      ]);
    },
  );
}

// ---------------------------------------------------------------- the late fine

/// The chit's late fine: what each late payment adds to that month's pot.
/// Returns the new amount (0 for no fine), or null when the sheet is closed.
Future<int?> askFine(BuildContext context, int current, String currency) {
  final s = S.of(context);
  final cur = currencyOf(currency);
  final c = TextEditingController(text: current > 0 ? '$current' : '');
  return showKSheet<int>(
    context,
    title: s.lateFine,
    builder: (ctx) {
      void done() => Navigator.of(ctx).pop(int.tryParse(c.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
          style: T.bodyStrong,
          decoration: InputDecoration(hintText: s.fineNone, prefixText: '${cur.symbol} ', prefixStyle: T.bodyStrong.copyWith(color: K.muted)),
          onSubmitted: (_) => done(),
        ),
        const SizedBox(height: Sp.sm),
        Text(s.fineSheetText, style: T.small),
        const SizedBox(height: Sp.lg),
        KButton(label: s.save, icon: Icons.check_rounded, expand: true, onPressed: done),
      ]);
    },
  );
}

// ---------------------------------------------------------------- the members' link

/// The private link: copy, share, open. Returns true when the admin asks for
/// a new link.
Future<bool?> showLinkSheet(BuildContext context, KuriDoc doc, String token) {
  final s = S.of(context);
  final url = shareUrl(token);
  return showKSheet<bool>(
    context,
    title: s.membersLink,
    builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(s.linkExplain, style: T.small),
      const SizedBox(height: Sp.lg),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: K.surface2, borderRadius: BorderRadius.circular(K.rMd), border: Border.all(color: K.border2)),
        child: SelectableText(url, textDirection: TextDirection.ltr, style: T.bodyStrong.copyWith(fontSize: 14)),
      ),
      const SizedBox(height: Sp.md),
      Row(children: [
        Expanded(
          child: KButton(
            label: s.copy,
            icon: Icons.copy_rounded,
            kind: KButtonKind.secondary,
            expand: true,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (ctx.mounted) toast(ctx, s.linkCopied);
            },
          ),
        ),
        const SizedBox(width: Sp.md - 2),
        Expanded(
          child: KButton(
            label: s.whatsapp,
            icon: Icons.chat_outlined,
            expand: true,
            onPressed: () => _open(ctx, whatsApp('${doc.fullName}\n$url')),
          ),
        ),
      ]),
      const SizedBox(height: Sp.md - 2),
      Row(children: [
        Expanded(
          child: KButton(
            label: s.open,
            icon: Icons.open_in_new_rounded,
            kind: KButtonKind.secondary,
            expand: true,
            onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
        ),
        const SizedBox(width: Sp.md - 2),
        Expanded(
          child: KButton(
            label: s.share,
            icon: Icons.ios_share_rounded,
            kind: KButtonKind.secondary,
            expand: true,
            onPressed: () => SharePlus.instance.share(ShareParams(text: '${doc.fullName}\n$url')),
          ),
        ),
      ]),
      const SizedBox(height: Sp.lg),
      Center(
        child: KButton(
          label: s.newLinkYes,
          icon: Icons.restart_alt_rounded,
          kind: KButtonKind.ghost,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ),
    ]),
  );
}
