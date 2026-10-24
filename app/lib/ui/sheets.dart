import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../core/kuri.dart';
import '../core/messages.dart';
import 'sign_in.dart';
import 'theme.dart';
import 'widgets.dart';

// ---------------------------------------------------------------- draw the rest

/// Every slot still to take the pot, shuffled over the months from next month
/// on. A slot is drawn as a whole, so a shared slot is one draw and a person
/// with two slots has two. Returns month -> slot when the admin uses the order.
Future<Map<int, int>?> showDrawRestSheet(BuildContext context, KuriDoc doc, int currentMonth) {
  final slots = doc.waitingSlots();
  final months = [for (final m in doc.months) if (m.n > currentMonth && m.winner == null) m.n];
  if (months.isEmpty || slots.isEmpty) {
    toast(context, months.isEmpty ? 'Every month from next month on already has someone taking the pot.' : 'Every slot has already taken the pot.',
        bad: true);
    return Future.value(null);
  }
  var order = shuffled(slots);
  return showKSheet<Map<int, int>>(
    context,
    title: 'Draw the rest',
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      final extra = order.length > months.length ? order.sublist(months.length) : <int>[];
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          '${slots.length} slots still to take the pot, over ${months.length} ${months.length == 1 ? 'month' : 'months'} from ${doc.monthLabel(months.first)}. '
          'Each slot is one draw.',
          style: T.small,
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < months.length; i++)
          TweenAnimationBuilder<double>(
            key: ValueKey('${order.join(',')}-$i'),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 260 + i * 40),
            curve: Curves.easeOutCubic,
            builder: (_, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, (1 - t) * 10), child: child)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: K.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: K.border)),
              child: Row(children: [
                SizedBox(
                  width: 124,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Month ${months[i]}', style: T.bodyStrong),
                    Text(doc.monthLabel(months[i]), style: T.small),
                  ]),
                ),
                if (i < order.length) ...[
                  SlotBadge('${order[i]}', size: 36, style: SlotBadgeStyle.sun),
                  const SizedBox(width: 10),
                  Expanded(child: Text(doc.slotName(order[i]), style: T.bodyStrong)),
                ] else
                  Expanded(child: Text('No slot left', style: T.small)),
              ]),
            ),
          ),
        if (extra.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Not placed (no month left for them): ${extra.map((s) => '$s. ${doc.slotName(s)}').join(', ')}', style: T.small),
          ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: KButton(
              label: 'Shuffle again',
              icon: Icons.shuffle_rounded,
              kind: KButtonKind.secondary,
              expand: true,
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() => order = shuffled(slots));
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: KButton(
              label: 'Use this order',
              icon: Icons.check_rounded,
              expand: true,
              onPressed: () async {
                final ok = await confirm(ctx,
                    title: 'Use this order?',
                    text: 'This sets who takes the pot for ${months.length} months. You can still change any month by hand before saving.',
                    yes: 'Use it');
                if (!ok || !ctx.mounted) return;
                Navigator.of(ctx).pop({for (var i = 0; i < months.length && i < order.length; i++) months[i]: order[i]});
              },
            ),
          ),
        ]),
      ]);
    }),
  );
}

// ---------------------------------------------------------------- reminders

/// The whole list for the group in one tap, or each person on their own,
/// ticked off as they are sent.
Future<void> showRemindersSheet(BuildContext context, KuriDoc doc, Month m, String token,
    {required Future<void> Function(Person) onAddNumber}) {
  final sent = <String>{};
  return showKSheet<void>(
    context,
    title: 'Reminders, month ${m.n}',
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      final dues = doc.dues(m);
      final withNo = dues.where((d) => d.person.phone.isNotEmpty).length;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        KButton(
          label: 'Share the list in the group',
          icon: Icons.groups_rounded,
          expand: true,
          onPressed: () => _open(ctx, whatsApp(groupList(doc, m, token))),
        ),
        const SizedBox(height: 10),
        Text(
          dues.isEmpty
              ? 'Everyone has paid, so there is nobody to remind.'
              : 'Or message each person. ${withNo < dues.length ? (dues.length - withNo == 1 ? '1 has no number yet.' : '${dues.length - withNo} have no number yet.') : 'Everyone here has a number.'}',
          style: T.small,
        ),
        const SizedBox(height: 12),
        for (final d in dues)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              color: sent.contains(d.person.id) ? K.brand100 : K.surface,
              borderRadius: BorderRadius.circular(16),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.person.name, style: T.bodyStrong),
                  Text(
                    d.person.phone.isEmpty ? 'No number yet' : '${money(d.amount)} due, month ${m.n}',
                    style: T.small.copyWith(color: d.person.phone.isEmpty ? K.warn : K.muted),
                  ),
                ]),
              ),
              if (d.person.phone.isEmpty)
                KButton(
                  label: 'Add number',
                  icon: Icons.phone_outlined,
                  kind: KButtonKind.secondary,
                  small: true,
                  onPressed: () async {
                    await onAddNumber(d.person);
                    setState(() {});
                  },
                )
              else
                KButton(
                  label: sent.contains(d.person.id) ? 'Sent' : 'Remind',
                  icon: sent.contains(d.person.id) ? Icons.check_rounded : Icons.chat_outlined,
                  kind: sent.contains(d.person.id) ? KButtonKind.ghost : KButtonKind.primary,
                  small: true,
                  onPressed: () {
                    setState(() => sent.add(d.person.id));
                    _open(ctx, whatsApp(reminderFor(doc, m, d), phone: d.person.phone));
                  },
                ),
            ]),
          ),
      ]);
    }),
  );
}

Future<void> _open(BuildContext context, Uri uri) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) toast(context, 'Could not open WhatsApp.', bad: true);
}

/// Asks for one person's WhatsApp number.
Future<String?> askPhone(BuildContext context, String name, String current) {
  var cc = '91';
  final c = TextEditingController(text: current.isEmpty ? '' : prettyPhone(current));
  String? error;
  return showKSheet<String>(
    context,
    title: '$name\'s number',
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      void done() {
        final p = c.text.trim().startsWith('+') ? phoneDigits(c.text) : fullPhone(cc, c.text);
        if (p.isEmpty || p.length < 8) {
          setState(() => error = 'Enter the WhatsApp number.');
          return;
        }
        Navigator.of(ctx).pop(p);
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (error != null) ...[Notice(error!), const SizedBox(height: 12)],
        Row(children: [
          CountryButton(code: cc, onChanged: (v) => setState(() => cc = v)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: c,
              autofocus: true,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
              style: T.bodyStrong,
              decoration: const InputDecoration(hintText: 'WhatsApp number'),
              onSubmitted: (_) => done(),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text('Used only for reminders. Members never see it.', style: T.small),
        const SizedBox(height: 14),
        KButton(label: 'Save number', icon: Icons.check_rounded, expand: true, onPressed: done),
      ]);
    }),
  );
}

// ---------------------------------------------------------------- the members' link

/// The private link: copy, share, open. Returns true when the admin asks for
/// a new link.
Future<bool?> showLinkSheet(BuildContext context, KuriDoc doc, String token) {
  final url = shareUrl(token);
  return showKSheet<bool>(
    context,
    title: 'Members\' link',
    builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Members open this in any browser. They see who paid, the fines, who took the pot and what is next. No app or sign-in, and no phone numbers.',
          style: T.small),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: K.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: K.border2)),
        child: SelectableText(url, style: T.bodyStrong.copyWith(fontSize: 14)),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: KButton(
            label: 'Copy',
            icon: Icons.copy_rounded,
            kind: KButtonKind.secondary,
            expand: true,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (ctx.mounted) toast(ctx, 'Link copied');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: KButton(
            label: 'WhatsApp',
            icon: Icons.chat_outlined,
            expand: true,
            onPressed: () => _open(ctx, whatsApp('${doc.fullName}\n$url')),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: KButton(
            label: 'Open',
            icon: Icons.open_in_new_rounded,
            kind: KButtonKind.secondary,
            expand: true,
            onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: KButton(
            label: 'Share',
            icon: Icons.ios_share_rounded,
            kind: KButtonKind.secondary,
            expand: true,
            onPressed: () => SharePlus.instance.share(ShareParams(text: '${doc.fullName}\n$url')),
          ),
        ),
      ]),
      const SizedBox(height: 18),
      KButton(
        label: 'Make a new link',
        icon: Icons.restart_alt_rounded,
        kind: KButtonKind.ghost,
        onPressed: () => Navigator.of(ctx).pop(true),
      ),
    ]),
  );
}
