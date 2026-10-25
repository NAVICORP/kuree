// Written by tool/l10n.py from lib/l10n/app_*.arb. Do not edit by hand:
// change the ARB files and run `python3 tool/l10n.py` from the app folder.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Every word the app shows, in one of its six languages.
class S {
  S._(this.code, this._t);

  /// "en", "ar", "ml", "ta", "kn" or "hi".
  final String code;
  final Map<String, String> _t;

  static const codes = <String>['en', 'ar', 'ml', 'ta', 'kn', 'hi'];

  /// Each language in its own script, for the language picker.
  static const names = <String, String>{'en': 'English', 'ar': 'العربية', 'ml': 'മലയാളം', 'ta': 'தமிழ்', 'kn': 'ಕನ್ನಡ', 'hi': 'हिन्दी'};

  static final Map<String, S> _cache = {};

  static S forCode(String code) {
    final c = codes.contains(code) ? code : 'en';
    return _cache.putIfAbsent(c, () => S._(c, _tables[c]!));
  }

  /// The language in use, for code without a BuildContext (messages,
  /// errors). Kept in step by the delegate and the language picker.
  static S current = forCode('en');

  static S of(BuildContext context) => Localizations.of<S>(context, S) ?? current;

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  bool get isRtl => code == 'ar';
  TextDirection get direction => isRtl ? TextDirection.rtl : TextDirection.ltr;

  @visibleForTesting
  static Map<String, String> table(String code) => _tables[code]!;

  String _get(String key) => _t[key] ?? _en[key] ?? key;

  String _fill(String key, Map<String, Object> args) {
    var s = _get(key);
    args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }

  /// January to December.
  late final List<String> monthsLong = [for (var i = 1; i <= 12; i++) _get('month$i')];

  /// Jan to Dec.
  late final List<String> monthsShort = [for (var i = 1; i <= 12; i++) _get('monthShort$i')];

  /// "Indian rupee" for INR.
  String currencyName(String code) => _t['currency$code'] ?? _en['currency$code'] ?? code;

  /// "India" for in.
  String countryName(String iso) => _t['country_$iso'] ?? _en['country_$iso'] ?? iso.toUpperCase();

  /// A language's name in this language: "Arabic" for ar.
  String languageName(String code) => _t['lang_$code'] ?? names[code] ?? code;

  /// Account
  String get account => _get('account');

  /// What should we call you?
  String get askNameTitle => _get('askNameTitle');

  /// Your 5K chit is in.
  String get importDone => _get('importDone');

  /// Bring in your 5K chit
  String get importTitle => _get('importTitle');

  /// Bring in
  String get importButton => _get('importButton');

  /// New chit
  String get newChit => _get('newChit');

  /// No chits yet.
  String get noChits => _get('noChits');

  /// Start a chit
  String get startChit => _get('startChit');

  /// Your chits
  String get yourChits => _get('yourChits');

  /// Admin
  String get roleAdmin => _get('roleAdmin');

  /// Month {n} of {total}, {label}
  String monthOfTotal(Object n, Object total, Object label) => _fill('monthOfTotal', {'n': n, 'total': total, 'label': label});

  /// of {amount}
  String ofAmount(Object amount) => _fill('ofAmount', {'amount': amount});

  /// {paid} of {total} paid
  String paidOfTotal(Object paid, Object total) => _fill('paidOfTotal', {'paid': paid, 'total': total});

  /// Collection {day} {month}, {note}
  String collectionNote(Object day, Object month, Object note) => _fill('collectionNote', {'day': day, 'month': month, 'note': note});

  /// Takes the pot: {name}
  String takesPotName(Object name) => _fill('takesPotName', {'name': name});

  /// Your name
  String get yourName => _get('yourName');

  /// Save
  String get save => _get('save');

  /// Cancel
  String get cancel => _get('cancel');

  /// Close
  String get close => _get('close');

  /// Yes
  String get yes => _get('yes');

  /// Try again
  String get tryAgain => _get('tryAgain');

  /// Language
  String get language => _get('language');

  /// Same as phone
  String get languagePhone => _get('languagePhone');

  /// just now
  String get agoJustNow => _get('agoJustNow');

  /// {n} min ago
  String agoMinutes(Object n) => _fill('agoMinutes', {'n': n});

  /// today, {time}
  String agoToday(Object time) => _fill('agoToday', {'time': time});

  /// yesterday, {time}
  String agoYesterday(Object time) => _fill('agoYesterday', {'time': time});

  /// am
  String get am => _get('am');

  /// pm
  String get pm => _get('pm');

  /// {first} and {last}
  String andJoin(Object first, Object last) => _fill('andJoin', {'first': first, 'last': last});

  /// Slot {n}
  String slotN(Object n) => _fill('slotN', {'n': n});

  /// Someone
  String get someone => _get('someone');

  /// ½ share
  String get shareHalf => _get('shareHalf');

  /// ⅓ share
  String get shareThird => _get('shareThird');

  /// ¼ share
  String get shareQuarter => _get('shareQuarter');

  /// {amount} share
  String shareAmount(Object amount) => _fill('shareAmount', {'amount': amount});

  /// in {n} days
  String noteInDays(Object n) => _fill('noteInDays', {'n': n});

  /// tomorrow
  String get noteTomorrow => _get('noteTomorrow');

  /// today
  String get noteToday => _get('noteToday');

  /// {n} days left to pay
  String noteDaysLeft(Object n) => _fill('noteDaysLeft', {'n': n});

  /// last day tomorrow
  String get noteLastDayTomorrow => _get('noteLastDayTomorrow');

  /// pay by midnight today
  String get notePayToday => _get('notePayToday');

  /// deadline passed
  String get noteDeadlinePassed => _get('noteDeadlinePassed');

  /// Your sign-in has ended. Sign in again.
  String get errSessionEnded => _get('errSessionEnded');

  /// Sign in again.
  String get errSignInAgain => _get('errSignInAgain');

  /// Offline.
  String get errOffline => _get('errOffline');

  /// The server took too long to answer. Check your connection and try again.
  String get errTimeout => _get('errTimeout');

  /// No connection. Check your internet and try again.
  String get errNoConnection => _get('errNoConnection');

  /// The Kuree server had a problem. Try again in a minute.
  String get errServer => _get('errServer');

  /// Something went wrong ({status}).
  String errStatus(Object status) => _fill('errStatus', {'status': status});

  /// This number is not on WhatsApp.
  String get errNotOnWhatsApp => _get('errNotOnWhatsApp');

  /// We could not send the code. Try again in a minute.
  String get errCouldNotSend => _get('errCouldNotSend');

  /// Too many tries. Wait a minute and try again.
  String get errTooMany => _get('errTooMany');

  /// That code is wrong or has expired. Ask for a new one.
  String get errWrongCode => _get('errWrongCode');

  /// That email and password do not match.
  String get errPasswordMismatch => _get('errPasswordMismatch');

  /// Enter your WhatsApp number with the country code.
  String get errPhoneCountry => _get('errPhoneCountry');

  /// That email does not look right.
  String get errEmailLooksWrong => _get('errEmailLooksWrong');

  /// The sign-in did not finish. Try again.
  String get errSignInNotFinished => _get('errSignInNotFinished');

  /// The file could not be made just now. Try again in a minute.
  String get errFile => _get('errFile');

  /// Hi {name}, a reminder: your {chit} payment of {amount} for month {n} ({label}) is due by midnight on the {day}.
  String msgReminder(Object name, Object chit, Object amount, Object n, Object label, Object day) => _fill('msgReminder', {'name': name, 'chit': chit, 'amount': amount, 'n': n, 'label': label, 'day': day});

  /// Hi {name}, a reminder from {group}: your {chit} payment of {amount} for month {n} ({label}) is due by midnight on the {day}.
  String msgReminderFrom(Object name, Object group, Object chit, Object amount, Object n, Object label, Object day) => _fill('msgReminderFrom', {'name': name, 'group': group, 'chit': chit, 'amount': amount, 'n': n, 'label': label, 'day': day});

  /// After that there is a late fine of {fine}.
  String msgFineAfter(Object fine) => _fill('msgFineAfter', {'fine': fine});

  /// Thank you.
  String get msgThanks => _get('msgThanks');

  /// {month} : Paid
  String msgPaidHead(Object month) => _fill('msgPaidHead', {'month': month});

  /// {month} : Not paid yet
  String msgDueHead(Object month) => _fill('msgDueHead', {'month': month});

  /// {chit}, month {n} ({label}) The bottle picked: {slot}. {name} Takes the pot of {pot}. {count} names were in the bottle. Drawn {when}.
  String msgDrawResult(Object chit, Object n, Object label, Object slot, Object name, Object pot, Object count, Object when) => _fill('msgDrawResult', {'chit': chit, 'n': n, 'label': label, 'slot': slot, 'name': name, 'pot': pot, 'count': count, 'when': when});

  /// Saved. Members see it now.
  String get savedMembersSee => _get('savedMembersSee');

  /// Someone else saved this
  String get conflictTitle => _get('conflictTitle');

  /// Another admin saved this chit a moment ago. Reload to see their change, then make yours again.
  String get conflictText => _get('conflictText');

  /// Reload
  String get reload => _get('reload');

  /// Nobody yet
  String get nobodyYet => _get('nobodyYet');

  /// Clear the choice
  String get clearChoice => _get('clearChoice');

  /// Takes the pot in month {n}
  String takesPotInMonth(Object n) => _fill('takesPotInMonth', {'n': n});

  /// Every slot has already taken the pot.
  String get allSlotsTaken => _get('allSlotsTaken');

  /// Only {name} is left, so there is nothing to draw. Use Choose.
  String onlyOneLeft(Object name) => _fill('onlyOneLeft', {'name': name});

  /// Saved. Month {n} goes to {name}.
  String savedMonthGoesTo(Object n, Object name) => _fill('savedMonthGoesTo', {'n': n, 'name': name});

  /// Draw done. Press Save to publish it.
  String get drawDonePressSave => _get('drawDonePressSave');

  /// Number added. Press Save to keep it.
  String get numberAddedPressSave => _get('numberAddedPressSave');

  /// Add names below. Each name is one slot, and the chit runs one month per slot.
  String get slotsFromNames => _get('slotsFromNames');

  /// Late fine {fine}
  String fineChip(Object fine) => _fill('fineChip', {'fine': fine});

  /// {fine} for each late payment
  String fineEach(Object fine) => _fill('fineEach', {'fine': fine});

  /// Add a late fine
  String get addLateFine => _get('addLateFine');

  /// Added to that month's pot for each late payment. Fines already marked keep their amount.
  String get fineSheetText => _get('fineSheetText');

  /// Late fine is now {fine}. Press Save to keep it.
  String fineChangedPressSave(Object fine) => _fill('fineChangedPressSave', {'fine': fine});

  /// No late fine from now on. Press Save to keep it.
  String get fineOffPressSave => _get('fineOffPressSave');

  /// Make a new link?
  String get newLinkTitle => _get('newLinkTitle');

  /// The old link stops working straight away. Share the new one in the group.
  String get newLinkText => _get('newLinkText');

  /// Make a new link
  String get newLinkYes => _get('newLinkYes');

  /// Making the spreadsheet…
  String get makingSheet => _get('makingSheet');

  /// Save first?
  String get saveFirstTitle => _get('saveFirstTitle');

  /// Save this month's changes before editing the chit.
  String get saveFirstText => _get('saveFirstText');

  /// Delete {name}?
  String deleteChitTitle(Object name) => _fill('deleteChitTitle', {'name': name});

  /// The chit, its history and the members' link are deleted for good. This cannot be undone.
  String get deleteChitText => _get('deleteChitText');

  /// Delete
  String get delete => _get('delete');

  /// Members' link
  String get membersLink => _get('membersLink');

  /// Share it in the group
  String get membersLinkSub => _get('membersLinkSub');

  /// Draw the rest
  String get drawRest => _get('drawRest');

  /// Shuffle every month still open
  String get drawRestSub => _get('drawRestSub');

  /// Spreadsheet
  String get spreadsheet => _get('spreadsheet');

  /// Every month, every member
  String get spreadsheetSub => _get('spreadsheetSub');

  /// History
  String get history => _get('history');

  /// Every earlier version
  String get historySub => _get('historySub');

  /// Admins
  String get admins => _get('admins');

  /// Who runs this chit
  String get adminsSub => _get('adminsSub');

  /// Edit chit
  String get editChit => _get('editChit');

  /// Name, amounts, currency, dates, slots, people
  String get editChitSub => _get('editChitSub');

  /// Delete chit
  String get deleteChit => _get('deleteChit');

  /// Leave without saving?
  String get leaveTitle => _get('leaveTitle');

  /// Your changes to this month are not saved yet.
  String get leaveText => _get('leaveText');

  /// Leave
  String get leave => _get('leave');

  /// More
  String get more => _get('more');

  /// Save your changes first.
  String get saveChangesFirst => _get('saveChangesFirst');

  /// Every save is kept in History, so nothing is lost.
  String get historyKept => _get('historyKept');

  /// Last saved by {name}, {when}
  String lastSavedBy(Object name, Object when) => _fill('lastSavedBy', {'name': name, 'when': when});

  /// Not saved yet
  String get notSavedYet => _get('notSavedYet');

  /// Undo
  String get undo => _get('undo');

  /// Previous month
  String get prevMonth => _get('prevMonth');

  /// Next month
  String get nextMonth => _get('nextMonth');

  /// Previous year
  String get prevYear => _get('prevYear');

  /// Next year
  String get nextYear => _get('nextYear');

  /// Month {n}, {label}
  String monthNLabel(Object n, Object label) => _fill('monthNLabel', {'n': n, 'label': label});

  /// of {pot} collected
  String collectedOf(Object pot) => _fill('collectedOf', {'pot': pot});

  /// of {pot} collected, plus {fines} in fines
  String collectedOfFines(Object pot, Object fines) => _fill('collectedOfFines', {'pot': pot, 'fines': fines});

  /// {n} to go
  String toGo(Object n) => _fill('toGo', {'n': n});

  /// Everyone paid
  String get everyonePaid => _get('everyonePaid');

  /// Collection {day} {month}, pay by {payDay} {payMonth}: {note}
  String heroCollection(Object day, Object month, Object payDay, Object payMonth, Object note) => _fill('heroCollection', {'day': day, 'month': month, 'payDay': payDay, 'payMonth': payMonth, 'note': note});

  /// Month
  String get month => _get('month');

  /// Settled
  String get settled => _get('settled');

  /// In progress
  String get inProgress => _get('inProgress');

  /// In progress, {name} takes the pot
  String inProgressTakes(Object name) => _fill('inProgressTakes', {'name': name});

  /// Upcoming
  String get upcoming => _get('upcoming');

  /// Upcoming, {name} takes the pot
  String upcomingTakes(Object name) => _fill('upcomingTakes', {'name': name});

  /// {total} (pot plus {fine} fine)
  String winnerAmountFine(Object total, Object fine) => _fill('winnerAmountFine', {'total': total, 'fine': fine});

  /// {amount}, picked from the bottle
  String pickedFromBottle(Object amount) => _fill('pickedFromBottle', {'amount': amount});

  /// Takes the pot this month
  String get takesPotThisMonth => _get('takesPotThisMonth');

  /// Not decided yet
  String get notDecided => _get('notDecided');

  /// Bottle draw
  String get bottleDraw => _get('bottleDraw');

  /// Choose
  String get choose => _get('choose');

  /// Change
  String get change => _get('change');

  /// All paid
  String get allPaid => _get('allPaid');

  /// Reminders
  String get reminders => _get('reminders');

  /// Everyone paid for month {n}
  String everyonePaidFor(Object n) => _fill('everyonePaidFor', {'n': n});

  /// Show
  String get showList => _get('showList');

  /// Hide
  String get hideList => _get('hideList');

  /// All {n}
  String filterAll(Object n) => _fill('filterAll', {'n': n});

  /// To pay {n}
  String filterDue(Object n) => _fill('filterDue', {'n': n});

  /// Paid {n}
  String filterPaid(Object n) => _fill('filterPaid', {'n': n});

  /// Tap the tick when someone pays. Tap Late if they paid after the last date.
  String get tickHelp => _get('tickHelp');

  /// Everyone has paid for month {n}.
  String everyonePaidMonth(Object n) => _fill('everyonePaidMonth', {'n': n});

  /// Nobody has paid for month {n} yet.
  String nobodyPaidMonth(Object n) => _fill('nobodyPaidMonth', {'n': n});

  /// Paid {amount}
  String statusPaid(Object amount) => _fill('statusPaid', {'amount': amount});

  /// Pending {amount}
  String statusPending(Object amount) => _fill('statusPending', {'amount': amount});

  /// {status}, late fine {fine}
  String statusLateFine(Object status, Object fine) => _fill('statusLateFine', {'status': status, 'fine': fine});

  /// Month {n}
  String monthN(Object n) => _fill('monthN', {'n': n});

  /// Paid: {name}
  String semPaid(Object name) => _fill('semPaid', {'name': name});

  /// Late fine, {name}
  String semLate(Object name) => _fill('semLate', {'name': name});

  /// Late
  String get lateButton => _get('lateButton');

  /// Could not open that. Is WhatsApp installed?
  String get couldNotOpen => _get('couldNotOpen');

  /// Copied
  String get copied => _get('copied');

  /// Month {n} draw
  String drawTitle(Object n) => _fill('drawTitle', {'n': n});

  /// {label}, pot {pot}
  String drawSubtitle(Object label, Object pot) => _fill('drawSubtitle', {'label': label, 'pot': pot});

  /// Saved to your photos.
  String get savedToPhotos => _get('savedToPhotos');

  /// The video could not be made on this phone.
  String get videoFailed => _get('videoFailed');

  /// {title}, month {n} draw
  String drawShareTitle(Object title, Object n) => _fill('drawShareTitle', {'title': title, 'n': n});

  /// Stop the draw?
  String get stopDrawTitle => _get('stopDrawTitle');

  /// Nothing is saved.
  String get nothingSaved => _get('nothingSaved');

  /// Stop
  String get stop => _get('stop');

  /// Close without saving?
  String get closeUnsavedTitle => _get('closeUnsavedTitle');

  /// The winner is not saved yet.
  String get winnerNotSaved => _get('winnerNotSaved');

  /// {n} slips go in the bottle, one for every slot still waiting for the pot.
  String slipsGoIn(Object n) => _fill('slipsGoIn', {'n': n});

  /// Hold another phone over this screen and start recording, then press Start the draw. It counts down from 3.
  String get recordHint => _get('recordHint');

  /// Music and sound effects
  String get musicSound => _get('musicSound');

  /// Getting ready
  String get gettingReady => _get('gettingReady');

  /// Start the draw
  String get startDraw => _get('startDraw');

  /// Takes the pot for month {n}, {label}.
  String takesPotFor(Object n, Object label) => _fill('takesPotFor', {'n': n, 'label': label});

  /// Saved
  String get saved => _get('saved');

  /// Save as month {n} winner
  String saveAsWinner(Object n) => _fill('saveAsWinner', {'n': n});

  /// Making the video {pct}%
  String makingVideo(Object pct) => _fill('makingVideo', {'pct': pct});

  /// Share the video
  String get shareVideo => _get('shareVideo');

  /// Save the video
  String get saveVideo => _get('saveVideo');

  /// Send the result on WhatsApp
  String get sendResultWa => _get('sendResultWa');

  /// Get ready
  String get drawGetReady => _get('drawGetReady');

  /// The draw starts in a moment
  String get drawStartsSoon => _get('drawStartsSoon');

  /// Writing every name
  String get drawWriting => _get('drawWriting');

  /// One slip for every slot still waiting for the pot
  String get drawWritingSub => _get('drawWritingSub');

  /// Into the bottle
  String get drawInto => _get('drawInto');

  /// Closing the bottle
  String get drawClosing => _get('drawClosing');

  /// Shaking
  String get drawShaking => _get('drawShaking');

  /// Every slip has the same chance
  String get drawShakingSub => _get('drawShakingSub');

  /// Picking one
  String get drawPicking => _get('drawPicking');

  /// {n} names in the bottle. Drawn {when}
  String drawFooterDrawn(Object n, Object when) => _fill('drawFooterDrawn', {'n': n, 'when': when});

  /// {n} names in the bottle. {when}
  String drawFooterNow(Object n, Object when) => _fill('drawFooterNow', {'n': n, 'when': when});

  /// Every month from next month on already has someone taking the pot.
  String get everyMonthTaken => _get('everyMonthTaken');

  /// {slots} slots still to take the pot, over {months} months from {from}. Each slot is one draw.
  String drawRestIntro(Object slots, Object months, Object from) => _fill('drawRestIntro', {'slots': slots, 'months': months, 'from': from});

  /// {slots} slots still to take the pot, over 1 month from {from}. Each slot is one draw.
  String drawRestIntroOne(Object slots, Object from) => _fill('drawRestIntroOne', {'slots': slots, 'from': from});

  /// No slot left
  String get noSlotLeft => _get('noSlotLeft');

  /// Not placed (no month left for them): {list}
  String notPlaced(Object list) => _fill('notPlaced', {'list': list});

  /// Use this order
  String get useThisOrder => _get('useThisOrder');

  /// Use this order?
  String get useOrderTitle => _get('useOrderTitle');

  /// This sets who takes the pot for {n} months. You can still change any month by hand before saving.
  String useOrderText(Object n) => _fill('useOrderText', {'n': n});

  /// Use it
  String get useIt => _get('useIt');

  /// Shuffle again
  String get shuffleAgain => _get('shuffleAgain');

  /// Reminders, month {n}
  String remindersTitle(Object n) => _fill('remindersTitle', {'n': n});

  /// Share the list in the group
  String get shareListInGroup => _get('shareListInGroup');

  /// Everyone has paid, so there is nobody to remind.
  String get nobodyToRemind => _get('nobodyToRemind');

  /// Or message each person. {rest}
  String remindEach(Object rest) => _fill('remindEach', {'rest': rest});

  /// Everyone here has a number.
  String get everyoneHasNumber => _get('everyoneHasNumber');

  /// 1 has no number yet.
  String get noNumberOne => _get('noNumberOne');

  /// {n} have no number yet.
  String noNumberMany(Object n) => _fill('noNumberMany', {'n': n});

  /// No number yet
  String get noNumberYet => _get('noNumberYet');

  /// {amount} due, month {n}
  String dueMonth(Object amount, Object n) => _fill('dueMonth', {'amount': amount, 'n': n});

  /// Add number
  String get addNumber => _get('addNumber');

  /// Sent
  String get sent => _get('sent');

  /// Remind
  String get remind => _get('remind');

  /// Could not open WhatsApp.
  String get couldNotOpenWa => _get('couldNotOpenWa');

  /// {name}'s number
  String numberTitle(Object name) => _fill('numberTitle', {'name': name});

  /// Enter the WhatsApp number.
  String get enterWaNumber => _get('enterWaNumber');

  /// WhatsApp number
  String get waNumberHint => _get('waNumberHint');

  /// Used only for reminders. Members never see it.
  String get numberUse => _get('numberUse');

  /// Save number
  String get saveNumber => _get('saveNumber');

  /// Members open this in any browser. They see who paid, the fines, who took the pot and what is next. No app or sign-in, and no phone numbers.
  String get linkExplain => _get('linkExplain');

  /// Copy
  String get copy => _get('copy');

  /// Link copied
  String get linkCopied => _get('linkCopied');

  /// WhatsApp
  String get whatsapp => _get('whatsapp');

  /// Open
  String get open => _get('open');

  /// Share
  String get share => _get('share');

  /// Give the chit a name, like 5K Chit.
  String get errNeedName => _get('errNeedName');

  /// Enter how much each slot pays a month.
  String get errNeedShare => _get('errNeedShare');

  /// Slot {n} needs a name.
  String errSlotName(Object n) => _fill('errSlotName', {'n': n});

  /// Slot {n}: the parts add up to {total}, but a slot pays {share}.
  String errPartsSum(Object n, Object total, Object share) => _fill('errPartsSum', {'n': n, 'total': total, 'share': share});

  /// Slot {n}: enter what each person pays.
  String errPartAmount(Object n) => _fill('errPartAmount', {'n': n});

  /// Month {n} already has payments or a taker, so the chit cannot have fewer than {n} slots.
  String errFewerSlots(Object n) => _fill('errFewerSlots', {'n': n});

  /// Slot {slot} took the pot in month {n}, so the chit needs at least {slot} slots.
  String errTakerSlot(Object slot, Object n) => _fill('errTakerSlot', {'slot': slot, 'n': n});

  /// Another admin saved this chit a moment ago. Go back, reload it, then make your changes again.
  String get errConflictEditor => _get('errConflictEditor');

  /// First month
  String get firstMonth => _get('firstMonth');

  /// Shorter months use their last day
  String get shorterMonths => _get('shorterMonths');

  /// Currency
  String get currency => _get('currency');

  /// Chit
  String get sectionChit => _get('sectionChit');

  /// Money
  String get sectionMoney => _get('sectionMoney');

  /// Dates
  String get sectionDates => _get('sectionDates');

  /// Name
  String get fieldName => _get('fieldName');

  /// 5K Chit
  String get nameHint => _get('nameHint');

  /// Group
  String get fieldGroup => _get('fieldGroup');

  /// Riverside
  String get groupHint => _get('groupHint');

  /// Each slot pays a month
  String get eachSlotPays => _get('eachSlotPays');

  /// Late fine
  String get lateFine => _get('lateFine');

  /// None
  String get fineNone => _get('fineNone');

  /// Slots
  String get slots => _get('slots');

  /// Fewer slots
  String get fewerSlots => _get('fewerSlots');

  /// More slots
  String get moreSlots => _get('moreSlots');

  /// Pot {pot} a month, for {n} months
  String potSummary(Object pot, Object n) => _fill('potSummary', {'pot': pot, 'n': n});

  /// One slot takes the pot each month, for {n} months
  String potSummaryNone(Object n) => _fill('potSummaryNone', {'n': n});

  /// Collection day
  String get collectionDay => _get('collectionDay');

  /// {day} of every month
  String everyMonthDay(Object day) => _fill('everyMonthDay', {'day': day});

  /// Last day to pay
  String get lastDayToPay => _get('lastDayToPay');

  /// {day}, by midnight
  String byMidnight(Object day) => _fill('byMidnight', {'day': day});

  /// {day}, by midnight, the month after
  String byMidnightNext(Object day) => _fill('byMidnightNext', {'day': day});

  /// One name per slot
  String get oneNamePerSlot => _get('oneNamePerSlot');

  /// Numbers for reminders
  String get numbersForReminders => _get('numbersForReminders');

  /// {a} of {b}
  String countOf(Object a, Object b) => _fill('countOf', {'a': a, 'b': b});

  /// Add names to the slots first.
  String get addNamesFirst => _get('addNamesFirst');

  /// Numbers are only for WhatsApp reminders. They never show on the members' link.
  String get numbersNote => _get('numbersNote');

  /// Start the chit
  String get startTheChit => _get('startTheChit');

  /// Save changes
  String get saveChanges => _get('saveChanges');

  /// Name {n}
  String nameN(Object n) => _fill('nameN', {'n': n});

  /// Remove
  String get remove => _get('remove');

  /// Split this slot
  String get splitSlot => _get('splitSlot');

  /// Add a person
  String get addPerson => _get('addPerson');

  /// Something went wrong. Try again.
  String get somethingWrong => _get('somethingWrong');

  /// Enter your WhatsApp number.
  String get enterYourWa => _get('enterYourWa');

  /// Enter the 6 digit code.
  String get enterCode => _get('enterCode');

  /// Enter the email and the password.
  String get enterEmailPassword => _get('enterEmailPassword');

  /// Check WhatsApp for the code.
  String get subPhoneCode => _get('subPhoneCode');

  /// Check your email for the code.
  String get subEmailCode => _get('subEmailCode');

  /// Sign in with your WhatsApp number.
  String get subPhone => _get('subPhone');

  /// Sign in with your email.
  String get subEmail => _get('subEmail');

  /// Run your chit from your phone.
  String get subStart => _get('subStart');

  /// Privacy
  String get privacy => _get('privacy');

  /// Terms
  String get terms => _get('terms');

  /// Continue with WhatsApp
  String get continueWa => _get('continueWa');

  /// Use email instead
  String get useEmailInstead => _get('useEmailInstead');

  /// Phone number
  String get phoneHint => _get('phoneHint');

  /// Send code on WhatsApp
  String get sendCodeWa => _get('sendCodeWa');

  /// We sent a 6 digit code on WhatsApp to {to}. It works for 10 minutes.
  String codeSentWa(Object to) => _fill('codeSentWa', {'to': to});

  /// We sent a 6 digit code to {to}. It works for 10 minutes.
  String codeSentEmail(Object to) => _fill('codeSentEmail', {'to': to});

  /// Sign in
  String get signIn => _get('signIn');

  /// Send again in {n}s
  String sendAgainIn(Object n) => _fill('sendAgainIn', {'n': n});

  /// Send again
  String get sendAgain => _get('sendAgain');

  /// Another number
  String get anotherNumber => _get('anotherNumber');

  /// Another email
  String get anotherEmail => _get('anotherEmail');

  /// Email
  String get email => _get('email');

  /// Email me a code
  String get emailMeCode => _get('emailMeCode');

  /// Use WhatsApp
  String get useWa => _get('useWa');

  /// Use a password
  String get usePassword => _get('usePassword');

  /// Password
  String get password => _get('password');

  /// Email me a code instead
  String get emailCodeInstead => _get('emailCodeInstead');

  /// Country code
  String get countryCode => _get('countryCode');

  /// Sign out?
  String get signOutTitle => _get('signOutTitle');

  /// Your chits stay safe on the server. Sign in again to see them.
  String get signOutText => _get('signOutText');

  /// Sign out
  String get signOut => _get('signOut');

  /// Delete your account?
  String get deleteAccountTitle => _get('deleteAccountTitle');

  /// Your Kuree account and name are deleted. Chits you own pass to their next admin. Chits only you run are deleted for good, with their history and members' links. This cannot be undone.
  String get deleteAccountText => _get('deleteAccountText');

  /// Also delete my SkiFi login
  String get deleteLoginToo => _get('deleteLoginToo');

  /// The number or email you sign in with. Other SkiFi apps you use with it lose it too.
  String get deleteLoginTooSub => _get('deleteLoginTooSub');

  /// Delete account
  String get deleteAccount => _get('deleteAccount');

  /// Deleting…
  String get deleting => _get('deleting');

  /// No name yet
  String get noNameYet => _get('noNameYet');

  /// Edit
  String get edit => _get('edit');

  /// Request a feature
  String get requestFeature => _get('requestFeature');

  /// Feature requests
  String get featureInbox => _get('featureInbox');

  /// Contact
  String get contact => _get('contact');

  /// month {n}: {a} paid, later {b}
  String histPaid(Object n, Object a, Object b) => _fill('histPaid', {'n': n, 'a': a, 'b': b});

  /// month {n} had no taker yet
  String histNoTaker(Object n) => _fill('histNoTaker', {'n': n});

  /// month {n} went to {name}
  String histWentTo(Object n, Object name) => _fill('histWentTo', {'n': n, 'name': name});

  /// month {n}: {count} late fines
  String histFines(Object n, Object count) => _fill('histFines', {'n': n, 'count': count});

  /// different settings
  String get histSettings => _get('histSettings');

  /// different people or slots
  String get histPeople => _get('histPeople');

  /// Small changes
  String get histSmall => _get('histSmall');

  /// and more
  String get histAndMore => _get('histAndMore');

  /// Put this version back?
  String get restoreTitle => _get('restoreTitle');

  /// The chit goes back to how {name} left it, {when}. What it shows now is kept in the history too, so you can undo this.
  String restoreText(Object name, Object when) => _fill('restoreText', {'name': name, 'when': when});

  /// Put it back
  String get putItBack => _get('putItBack');

  /// No earlier versions yet. Each save adds one.
  String get historyEmpty => _get('historyEmpty');

  /// Saved by {name}
  String savedBy(Object name) => _fill('savedBy', {'name': name});

  /// Put back
  String get putBack => _get('putBack');

  /// Add an admin
  String get addAnAdmin => _get('addAnAdmin');

  /// Added. They see this chit when they sign in.
  String get adminAdded => _get('adminAdded');

  /// Leave this chit?
  String get leaveChitTitle => _get('leaveChitTitle');

  /// Remove {name}?
  String removeAdminTitle(Object name) => _fill('removeAdminTitle', {'name': name});

  /// You will no longer see or change it.
  String get leaveChitText => _get('leaveChitText');

  /// They will no longer see or change this chit.
  String get removeAdminText => _get('removeAdminText');

  /// Make {name} the owner?
  String makeOwnerTitle(Object name) => _fill('makeOwnerTitle', {'name': name});

  /// They will be able to add and remove admins and delete the chit. You stay on as an admin.
  String get makeOwnerText => _get('makeOwnerText');

  /// Make owner
  String get makeOwner => _get('makeOwner');

  /// {name} owns the chit now.
  String ownsNow(Object name) => _fill('ownsNow', {'name': name});

  /// Add admin
  String get addAdmin => _get('addAdmin');

  /// Admins mark payments, run the draw and send reminders. The owner also adds and removes admins.
  String get adminsExplain => _get('adminsExplain');

  /// Owner
  String get roleOwner => _get('roleOwner');

  /// You
  String get you => _get('you');

  /// Leave this chit
  String get leaveChit => _get('leaveChit');

  /// Remove admin
  String get removeAdmin => _get('removeAdmin');

  /// Enter their WhatsApp number.
  String get enterTheirWa => _get('enterTheirWa');

  /// Enter their email.
  String get enterTheirEmail => _get('enterTheirEmail');

  /// Their name
  String get theirName => _get('theirName');

  /// Use email
  String get useEmail => _get('useEmail');

  /// They sign in to Kuree with this email to see the chit.
  String get adminSignInEmail => _get('adminSignInEmail');

  /// They sign in to Kuree with this number to see the chit.
  String get adminSignInNumber => _get('adminSignInNumber');

  /// Request a feature
  String get frTitle => _get('frTitle');

  /// Tell us what would help
  String get frIntroTitle => _get('frIntroTitle');

  /// An idea, something that gets in the way, a feature you miss. We read every request.
  String get frIntroText => _get('frIntroText');

  /// Your idea in a few words
  String get frFieldTitle => _get('frFieldTitle');

  /// For example: a reminder the day before
  String get frFieldTitleHint => _get('frFieldTitleHint');

  /// Tell us more (optional)
  String get frFieldDetails => _get('frFieldDetails');

  /// How would you use it? What happens today?
  String get frFieldDetailsHint => _get('frFieldDetailsHint');

  /// How much would it help?
  String get frImportance => _get('frImportance');

  /// Nice to have
  String get frNice => _get('frNice');

  /// Important
  String get frImportant => _get('frImportant');

  /// Must have
  String get frMust => _get('frMust');

  /// Send request
  String get frSend => _get('frSend');

  /// Give your idea a short title.
  String get frNeedTitle => _get('frNeedTitle');

  /// Thank you!
  String get frThanksTitle => _get('frThanksTitle');

  /// Your request reached the Kuree team. You can follow it below.
  String get frThanksText => _get('frThanksText');

  /// Send another
  String get frSendAnother => _get('frSendAnother');

  /// Your requests
  String get frYours => _get('frYours');

  /// Your requests will show here, with what the team decides.
  String get frNoneYet => _get('frNoneYet');

  /// From the Kuree team
  String get frReply => _get('frReply');

  /// Feature requests
  String get frInboxTitle => _get('frInboxTitle');

  /// No requests here yet.
  String get frInboxEmpty => _get('frInboxEmpty');

  /// All
  String get frAll => _get('frAll');

  /// New
  String get frStatusNew => _get('frStatusNew');

  /// Planned
  String get frStatusPlanned => _get('frStatusPlanned');

  /// Done
  String get frStatusDone => _get('frStatusDone');

  /// Declined
  String get frStatusDeclined => _get('frStatusDeclined');

  /// Update the request
  String get frChange => _get('frChange');

  /// Note for the person who asked (optional)
  String get frNoteLabel => _get('frNoteLabel');

  /// For example: coming in the next update
  String get frNoteHint => _get('frNoteHint');

  /// Saved.
  String get frSaved => _get('frSaved');

  /// From
  String get frFrom => _get('frFrom');

  /// Account deleted
  String get frSignedOut => _get('frSignedOut');

  /// Chits
  String get tabChits => _get('tabChits');

  /// To collect
  String get tabCollect => _get('tabCollect');

  /// Profile
  String get tabProfile => _get('tabProfile');

  /// Still to pay this month, across your chits.
  String get collectIntro => _get('collectIntro');

  /// Everyone has paid this month, in every chit.
  String get nothingToCollect => _get('nothingToCollect');

  /// Preferences
  String get secPreferences => _get('secPreferences');

  /// Help
  String get secHelp => _get('secHelp');

  /// Legal
  String get secLegal => _get('secLegal');
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) => S.codes.contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) {
    final s = S.forCode(locale.languageCode);
    S.current = s;
    return SynchronousFuture<S>(s);
  }

  @override
  bool shouldReload(_SDelegate old) => false;
}

const Map<String, String> _en = {
  'month1': 'January',
  'month2': 'February',
  'month3': 'March',
  'month4': 'April',
  'month5': 'May',
  'month6': 'June',
  'month7': 'July',
  'month8': 'August',
  'month9': 'September',
  'month10': 'October',
  'month11': 'November',
  'month12': 'December',
  'monthShort1': 'Jan',
  'monthShort2': 'Feb',
  'monthShort3': 'Mar',
  'monthShort4': 'Apr',
  'monthShort5': 'May',
  'monthShort6': 'Jun',
  'monthShort7': 'Jul',
  'monthShort8': 'Aug',
  'monthShort9': 'Sep',
  'monthShort10': 'Oct',
  'monthShort11': 'Nov',
  'monthShort12': 'Dec',
  'currencyINR': 'Indian rupee',
  'currencyAED': 'UAE dirham',
  'currencySAR': 'Saudi riyal',
  'currencyQAR': 'Qatari riyal',
  'currencyKWD': 'Kuwaiti dinar',
  'currencyOMR': 'Omani rial',
  'currencyBHD': 'Bahraini dinar',
  'currencyUSD': 'US dollar',
  'currencyGBP': 'British pound',
  'currencyEUR': 'Euro',
  'currencySGD': 'Singapore dollar',
  'currencyMYR': 'Malaysian ringgit',
  'currencyLKR': 'Sri Lankan rupee',
  'country_in': 'India',
  'country_ae': 'UAE',
  'country_sa': 'Saudi Arabia',
  'country_qa': 'Qatar',
  'country_kw': 'Kuwait',
  'country_om': 'Oman',
  'country_bh': 'Bahrain',
  'country_us': 'United States',
  'country_gb': 'United Kingdom',
  'country_au': 'Australia',
  'country_sg': 'Singapore',
  'country_my': 'Malaysia',
  'country_de': 'Germany',
  'lang_en': 'English',
  'lang_ar': 'Arabic',
  'lang_ml': 'Malayalam',
  'lang_ta': 'Tamil',
  'lang_kn': 'Kannada',
  'lang_hi': 'Hindi',
  'account': 'Account',
  'askNameTitle': 'What should we call you?',
  'importDone': 'Your 5K chit is in.',
  'importTitle': 'Bring in your 5K chit',
  'importButton': 'Bring in',
  'newChit': 'New chit',
  'noChits': 'No chits yet.',
  'startChit': 'Start a chit',
  'yourChits': 'Your chits',
  'roleAdmin': 'Admin',
  'monthOfTotal': 'Month {n} of {total}, {label}',
  'ofAmount': 'of {amount}',
  'paidOfTotal': '{paid} of {total} paid',
  'collectionNote': 'Collection {day} {month}, {note}',
  'takesPotName': 'Takes the pot: {name}',
  'yourName': 'Your name',
  'save': 'Save',
  'cancel': 'Cancel',
  'close': 'Close',
  'yes': 'Yes',
  'tryAgain': 'Try again',
  'language': 'Language',
  'languagePhone': 'Same as phone',
  'agoJustNow': 'just now',
  'agoMinutes': '{n} min ago',
  'agoToday': 'today, {time}',
  'agoYesterday': 'yesterday, {time}',
  'am': 'am',
  'pm': 'pm',
  'andJoin': '{first} and {last}',
  'slotN': 'Slot {n}',
  'someone': 'Someone',
  'shareHalf': '½ share',
  'shareThird': '⅓ share',
  'shareQuarter': '¼ share',
  'shareAmount': '{amount} share',
  'noteInDays': 'in {n} days',
  'noteTomorrow': 'tomorrow',
  'noteToday': 'today',
  'noteDaysLeft': '{n} days left to pay',
  'noteLastDayTomorrow': 'last day tomorrow',
  'notePayToday': 'pay by midnight today',
  'noteDeadlinePassed': 'deadline passed',
  'errSessionEnded': 'Your sign-in has ended. Sign in again.',
  'errSignInAgain': 'Sign in again.',
  'errOffline': 'Offline.',
  'errTimeout': 'The server took too long to answer. Check your connection and try again.',
  'errNoConnection': 'No connection. Check your internet and try again.',
  'errServer': 'The Kuree server had a problem. Try again in a minute.',
  'errStatus': 'Something went wrong ({status}).',
  'errNotOnWhatsApp': 'This number is not on WhatsApp.',
  'errCouldNotSend': 'We could not send the code. Try again in a minute.',
  'errTooMany': 'Too many tries. Wait a minute and try again.',
  'errWrongCode': 'That code is wrong or has expired. Ask for a new one.',
  'errPasswordMismatch': 'That email and password do not match.',
  'errPhoneCountry': 'Enter your WhatsApp number with the country code.',
  'errEmailLooksWrong': 'That email does not look right.',
  'errSignInNotFinished': 'The sign-in did not finish. Try again.',
  'errFile': 'The file could not be made just now. Try again in a minute.',
  'msgReminder': 'Hi {name}, a reminder: your {chit} payment of {amount} for month {n} ({label}) is due by midnight on the {day}.',
  'msgReminderFrom': 'Hi {name}, a reminder from {group}: your {chit} payment of {amount} for month {n} ({label}) is due by midnight on the {day}.',
  'msgFineAfter': ' After that there is a late fine of {fine}.',
  'msgThanks': ' Thank you.',
  'msgPaidHead': '{month} : Paid',
  'msgDueHead': '{month} : Not paid yet',
  'msgDrawResult': '{chit}, month {n} ({label})\nThe bottle picked: {slot}. {name}\nTakes the pot of {pot}.\n{count} names were in the bottle. Drawn {when}.',
  'savedMembersSee': 'Saved. Members see it now.',
  'conflictTitle': 'Someone else saved this',
  'conflictText': 'Another admin saved this chit a moment ago. Reload to see their change, then make yours again.',
  'reload': 'Reload',
  'nobodyYet': 'Nobody yet',
  'clearChoice': 'Clear the choice',
  'takesPotInMonth': 'Takes the pot in month {n}',
  'allSlotsTaken': 'Every slot has already taken the pot.',
  'onlyOneLeft': 'Only {name} is left, so there is nothing to draw. Use Choose.',
  'savedMonthGoesTo': 'Saved. Month {n} goes to {name}.',
  'drawDonePressSave': 'Draw done. Press Save to publish it.',
  'numberAddedPressSave': 'Number added. Press Save to keep it.',
  'slotsFromNames': 'Add names below. Each name is one slot, and the chit runs one month per slot.',
  'fineChip': 'Late fine {fine}',
  'fineEach': '{fine} for each late payment',
  'addLateFine': 'Add a late fine',
  'fineSheetText': 'Added to that month\'s pot for each late payment. Fines already marked keep their amount.',
  'fineChangedPressSave': 'Late fine is now {fine}. Press Save to keep it.',
  'fineOffPressSave': 'No late fine from now on. Press Save to keep it.',
  'newLinkTitle': 'Make a new link?',
  'newLinkText': 'The old link stops working straight away. Share the new one in the group.',
  'newLinkYes': 'Make a new link',
  'makingSheet': 'Making the spreadsheet…',
  'saveFirstTitle': 'Save first?',
  'saveFirstText': 'Save this month\'s changes before editing the chit.',
  'deleteChitTitle': 'Delete {name}?',
  'deleteChitText': 'The chit, its history and the members\' link are deleted for good. This cannot be undone.',
  'delete': 'Delete',
  'membersLink': 'Members\' link',
  'membersLinkSub': 'Share it in the group',
  'drawRest': 'Draw the rest',
  'drawRestSub': 'Shuffle every month still open',
  'spreadsheet': 'Spreadsheet',
  'spreadsheetSub': 'Every month, every member',
  'history': 'History',
  'historySub': 'Every earlier version',
  'admins': 'Admins',
  'adminsSub': 'Who runs this chit',
  'editChit': 'Edit chit',
  'editChitSub': 'Name, amounts, currency, dates, slots, people',
  'deleteChit': 'Delete chit',
  'leaveTitle': 'Leave without saving?',
  'leaveText': 'Your changes to this month are not saved yet.',
  'leave': 'Leave',
  'more': 'More',
  'saveChangesFirst': 'Save your changes first.',
  'historyKept': 'Every save is kept in History, so nothing is lost.',
  'lastSavedBy': 'Last saved by {name}, {when}',
  'notSavedYet': 'Not saved yet',
  'undo': 'Undo',
  'prevMonth': 'Previous month',
  'nextMonth': 'Next month',
  'prevYear': 'Previous year',
  'nextYear': 'Next year',
  'monthNLabel': 'Month {n}, {label}',
  'collectedOf': 'of {pot} collected',
  'collectedOfFines': 'of {pot} collected, plus {fines} in fines',
  'toGo': '{n} to go',
  'everyonePaid': 'Everyone paid',
  'heroCollection': 'Collection {day} {month}, pay by {payDay} {payMonth}: {note}',
  'month': 'Month',
  'settled': 'Settled',
  'inProgress': 'In progress',
  'inProgressTakes': 'In progress, {name} takes the pot',
  'upcoming': 'Upcoming',
  'upcomingTakes': 'Upcoming, {name} takes the pot',
  'winnerAmountFine': '{total} (pot plus {fine} fine)',
  'pickedFromBottle': '{amount}, picked from the bottle',
  'takesPotThisMonth': 'Takes the pot this month',
  'notDecided': 'Not decided yet',
  'bottleDraw': 'Bottle draw',
  'choose': 'Choose',
  'change': 'Change',
  'allPaid': 'All paid',
  'reminders': 'Reminders',
  'everyonePaidFor': 'Everyone paid for month {n}',
  'showList': 'Show',
  'hideList': 'Hide',
  'filterAll': 'All {n}',
  'filterDue': 'To pay {n}',
  'filterPaid': 'Paid {n}',
  'tickHelp': 'Tap the tick when someone pays. Tap Late if they paid after the last date.',
  'everyonePaidMonth': 'Everyone has paid for month {n}.',
  'nobodyPaidMonth': 'Nobody has paid for month {n} yet.',
  'statusPaid': 'Paid {amount}',
  'statusPending': 'Pending {amount}',
  'statusLateFine': '{status}, late fine {fine}',
  'monthN': 'Month {n}',
  'semPaid': 'Paid: {name}',
  'semLate': 'Late fine, {name}',
  'lateButton': 'Late',
  'couldNotOpen': 'Could not open that. Is WhatsApp installed?',
  'copied': 'Copied',
  'drawTitle': 'Month {n} draw',
  'drawSubtitle': '{label}, pot {pot}',
  'savedToPhotos': 'Saved to your photos.',
  'videoFailed': 'The video could not be made on this phone.',
  'drawShareTitle': '{title}, month {n} draw',
  'stopDrawTitle': 'Stop the draw?',
  'nothingSaved': 'Nothing is saved.',
  'stop': 'Stop',
  'closeUnsavedTitle': 'Close without saving?',
  'winnerNotSaved': 'The winner is not saved yet.',
  'slipsGoIn': '{n} slips go in the bottle, one for every slot still waiting for the pot.',
  'recordHint': 'Hold another phone over this screen and start recording, then press Start the draw. It counts down from 3.',
  'musicSound': 'Music and sound effects',
  'gettingReady': 'Getting ready',
  'startDraw': 'Start the draw',
  'takesPotFor': 'Takes the pot for month {n}, {label}.',
  'saved': 'Saved',
  'saveAsWinner': 'Save as month {n} winner',
  'makingVideo': 'Making the video {pct}%',
  'shareVideo': 'Share the video',
  'saveVideo': 'Save the video',
  'sendResultWa': 'Send the result on WhatsApp',
  'drawGetReady': 'Get ready',
  'drawStartsSoon': 'The draw starts in a moment',
  'drawWriting': 'Writing every name',
  'drawWritingSub': 'One slip for every slot still waiting for the pot',
  'drawInto': 'Into the bottle',
  'drawClosing': 'Closing the bottle',
  'drawShaking': 'Shaking',
  'drawShakingSub': 'Every slip has the same chance',
  'drawPicking': 'Picking one',
  'drawFooterDrawn': '{n} names in the bottle. Drawn {when}',
  'drawFooterNow': '{n} names in the bottle. {when}',
  'everyMonthTaken': 'Every month from next month on already has someone taking the pot.',
  'drawRestIntro': '{slots} slots still to take the pot, over {months} months from {from}. Each slot is one draw.',
  'drawRestIntroOne': '{slots} slots still to take the pot, over 1 month from {from}. Each slot is one draw.',
  'noSlotLeft': 'No slot left',
  'notPlaced': 'Not placed (no month left for them): {list}',
  'useThisOrder': 'Use this order',
  'useOrderTitle': 'Use this order?',
  'useOrderText': 'This sets who takes the pot for {n} months. You can still change any month by hand before saving.',
  'useIt': 'Use it',
  'shuffleAgain': 'Shuffle again',
  'remindersTitle': 'Reminders, month {n}',
  'shareListInGroup': 'Share the list in the group',
  'nobodyToRemind': 'Everyone has paid, so there is nobody to remind.',
  'remindEach': 'Or message each person. {rest}',
  'everyoneHasNumber': 'Everyone here has a number.',
  'noNumberOne': '1 has no number yet.',
  'noNumberMany': '{n} have no number yet.',
  'noNumberYet': 'No number yet',
  'dueMonth': '{amount} due, month {n}',
  'addNumber': 'Add number',
  'sent': 'Sent',
  'remind': 'Remind',
  'couldNotOpenWa': 'Could not open WhatsApp.',
  'numberTitle': '{name}\'s number',
  'enterWaNumber': 'Enter the WhatsApp number.',
  'waNumberHint': 'WhatsApp number',
  'numberUse': 'Used only for reminders. Members never see it.',
  'saveNumber': 'Save number',
  'linkExplain': 'Members open this in any browser. They see who paid, the fines, who took the pot and what is next. No app or sign-in, and no phone numbers.',
  'copy': 'Copy',
  'linkCopied': 'Link copied',
  'whatsapp': 'WhatsApp',
  'open': 'Open',
  'share': 'Share',
  'errNeedName': 'Give the chit a name, like 5K Chit.',
  'errNeedShare': 'Enter how much each slot pays a month.',
  'errSlotName': 'Slot {n} needs a name.',
  'errPartsSum': 'Slot {n}: the parts add up to {total}, but a slot pays {share}.',
  'errPartAmount': 'Slot {n}: enter what each person pays.',
  'errFewerSlots': 'Month {n} already has payments or a taker, so the chit cannot have fewer than {n} slots.',
  'errTakerSlot': 'Slot {slot} took the pot in month {n}, so the chit needs at least {slot} slots.',
  'errConflictEditor': 'Another admin saved this chit a moment ago. Go back, reload it, then make your changes again.',
  'firstMonth': 'First month',
  'shorterMonths': 'Shorter months use their last day',
  'currency': 'Currency',
  'sectionChit': 'Chit',
  'sectionMoney': 'Money',
  'sectionDates': 'Dates',
  'fieldName': 'Name',
  'nameHint': '5K Chit',
  'fieldGroup': 'Group',
  'groupHint': 'Riverside',
  'eachSlotPays': 'Each slot pays a month',
  'lateFine': 'Late fine',
  'fineNone': 'None',
  'slots': 'Slots',
  'fewerSlots': 'Fewer slots',
  'moreSlots': 'More slots',
  'potSummary': 'Pot {pot} a month, for {n} months',
  'potSummaryNone': 'One slot takes the pot each month, for {n} months',
  'collectionDay': 'Collection day',
  'everyMonthDay': '{day} of every month',
  'lastDayToPay': 'Last day to pay',
  'byMidnight': '{day}, by midnight',
  'byMidnightNext': '{day}, by midnight, the month after',
  'oneNamePerSlot': 'One name per slot',
  'numbersForReminders': 'Numbers for reminders',
  'countOf': '{a} of {b}',
  'addNamesFirst': 'Add names to the slots first.',
  'numbersNote': 'Numbers are only for WhatsApp reminders. They never show on the members\' link.',
  'startTheChit': 'Start the chit',
  'saveChanges': 'Save changes',
  'nameN': 'Name {n}',
  'remove': 'Remove',
  'splitSlot': 'Split this slot',
  'addPerson': 'Add a person',
  'somethingWrong': 'Something went wrong. Try again.',
  'enterYourWa': 'Enter your WhatsApp number.',
  'enterCode': 'Enter the 6 digit code.',
  'enterEmailPassword': 'Enter the email and the password.',
  'subPhoneCode': 'Check WhatsApp for the code.',
  'subEmailCode': 'Check your email for the code.',
  'subPhone': 'Sign in with your WhatsApp number.',
  'subEmail': 'Sign in with your email.',
  'subStart': 'Run your chit from your phone.',
  'privacy': 'Privacy',
  'terms': 'Terms',
  'continueWa': 'Continue with WhatsApp',
  'useEmailInstead': 'Use email instead',
  'phoneHint': 'Phone number',
  'sendCodeWa': 'Send code on WhatsApp',
  'codeSentWa': 'We sent a 6 digit code on WhatsApp to {to}. It works for 10 minutes.',
  'codeSentEmail': 'We sent a 6 digit code to {to}. It works for 10 minutes.',
  'signIn': 'Sign in',
  'sendAgainIn': 'Send again in {n}s',
  'sendAgain': 'Send again',
  'anotherNumber': 'Another number',
  'anotherEmail': 'Another email',
  'email': 'Email',
  'emailMeCode': 'Email me a code',
  'useWa': 'Use WhatsApp',
  'usePassword': 'Use a password',
  'password': 'Password',
  'emailCodeInstead': 'Email me a code instead',
  'countryCode': 'Country code',
  'signOutTitle': 'Sign out?',
  'signOutText': 'Your chits stay safe on the server. Sign in again to see them.',
  'signOut': 'Sign out',
  'deleteAccountTitle': 'Delete your account?',
  'deleteAccountText': 'Your Kuree account and name are deleted. Chits you own pass to their next admin. Chits only you run are deleted for good, with their history and members\' links. This cannot be undone.',
  'deleteLoginToo': 'Also delete my SkiFi login',
  'deleteLoginTooSub': 'The number or email you sign in with. Other SkiFi apps you use with it lose it too.',
  'deleteAccount': 'Delete account',
  'deleting': 'Deleting…',
  'noNameYet': 'No name yet',
  'edit': 'Edit',
  'requestFeature': 'Request a feature',
  'featureInbox': 'Feature requests',
  'contact': 'Contact',
  'histPaid': 'month {n}: {a} paid, later {b}',
  'histNoTaker': 'month {n} had no taker yet',
  'histWentTo': 'month {n} went to {name}',
  'histFines': 'month {n}: {count} late fines',
  'histSettings': 'different settings',
  'histPeople': 'different people or slots',
  'histSmall': 'Small changes',
  'histAndMore': 'and more',
  'restoreTitle': 'Put this version back?',
  'restoreText': 'The chit goes back to how {name} left it, {when}. What it shows now is kept in the history too, so you can undo this.',
  'putItBack': 'Put it back',
  'historyEmpty': 'No earlier versions yet. Each save adds one.',
  'savedBy': 'Saved by {name}',
  'putBack': 'Put back',
  'addAnAdmin': 'Add an admin',
  'adminAdded': 'Added. They see this chit when they sign in.',
  'leaveChitTitle': 'Leave this chit?',
  'removeAdminTitle': 'Remove {name}?',
  'leaveChitText': 'You will no longer see or change it.',
  'removeAdminText': 'They will no longer see or change this chit.',
  'makeOwnerTitle': 'Make {name} the owner?',
  'makeOwnerText': 'They will be able to add and remove admins and delete the chit. You stay on as an admin.',
  'makeOwner': 'Make owner',
  'ownsNow': '{name} owns the chit now.',
  'addAdmin': 'Add admin',
  'adminsExplain': 'Admins mark payments, run the draw and send reminders. The owner also adds and removes admins.',
  'roleOwner': 'Owner',
  'you': 'You',
  'leaveChit': 'Leave this chit',
  'removeAdmin': 'Remove admin',
  'enterTheirWa': 'Enter their WhatsApp number.',
  'enterTheirEmail': 'Enter their email.',
  'theirName': 'Their name',
  'useEmail': 'Use email',
  'adminSignInEmail': 'They sign in to Kuree with this email to see the chit.',
  'adminSignInNumber': 'They sign in to Kuree with this number to see the chit.',
  'frTitle': 'Request a feature',
  'frIntroTitle': 'Tell us what would help',
  'frIntroText': 'An idea, something that gets in the way, a feature you miss. We read every request.',
  'frFieldTitle': 'Your idea in a few words',
  'frFieldTitleHint': 'For example: a reminder the day before',
  'frFieldDetails': 'Tell us more (optional)',
  'frFieldDetailsHint': 'How would you use it? What happens today?',
  'frImportance': 'How much would it help?',
  'frNice': 'Nice to have',
  'frImportant': 'Important',
  'frMust': 'Must have',
  'frSend': 'Send request',
  'frNeedTitle': 'Give your idea a short title.',
  'frThanksTitle': 'Thank you!',
  'frThanksText': 'Your request reached the Kuree team. You can follow it below.',
  'frSendAnother': 'Send another',
  'frYours': 'Your requests',
  'frNoneYet': 'Your requests will show here, with what the team decides.',
  'frReply': 'From the Kuree team',
  'frInboxTitle': 'Feature requests',
  'frInboxEmpty': 'No requests here yet.',
  'frAll': 'All',
  'frStatusNew': 'New',
  'frStatusPlanned': 'Planned',
  'frStatusDone': 'Done',
  'frStatusDeclined': 'Declined',
  'frChange': 'Update the request',
  'frNoteLabel': 'Note for the person who asked (optional)',
  'frNoteHint': 'For example: coming in the next update',
  'frSaved': 'Saved.',
  'frFrom': 'From',
  'frSignedOut': 'Account deleted',
  'tabChits': 'Chits',
  'tabCollect': 'To collect',
  'tabProfile': 'Profile',
  'collectIntro': 'Still to pay this month, across your chits.',
  'nothingToCollect': 'Everyone has paid this month, in every chit.',
  'secPreferences': 'Preferences',
  'secHelp': 'Help',
  'secLegal': 'Legal',
};

const Map<String, String> _ar = {
  'month1': 'يناير',
  'month2': 'فبراير',
  'month3': 'مارس',
  'month4': 'أبريل',
  'month5': 'مايو',
  'month6': 'يونيو',
  'month7': 'يوليو',
  'month8': 'أغسطس',
  'month9': 'سبتمبر',
  'month10': 'أكتوبر',
  'month11': 'نوفمبر',
  'month12': 'ديسمبر',
  'monthShort1': 'يناير',
  'monthShort2': 'فبراير',
  'monthShort3': 'مارس',
  'monthShort4': 'أبريل',
  'monthShort5': 'مايو',
  'monthShort6': 'يونيو',
  'monthShort7': 'يوليو',
  'monthShort8': 'أغسطس',
  'monthShort9': 'سبتمبر',
  'monthShort10': 'أكتوبر',
  'monthShort11': 'نوفمبر',
  'monthShort12': 'ديسمبر',
  'currencyINR': 'روبية هندية',
  'currencyAED': 'درهم إماراتي',
  'currencySAR': 'ريال سعودي',
  'currencyQAR': 'ريال قطري',
  'currencyKWD': 'دينار كويتي',
  'currencyOMR': 'ريال عماني',
  'currencyBHD': 'دينار بحريني',
  'currencyUSD': 'دولار أمريكي',
  'currencyGBP': 'جنيه إسترليني',
  'currencyEUR': 'يورو',
  'currencySGD': 'دولار سنغافوري',
  'currencyMYR': 'رينغيت ماليزي',
  'currencyLKR': 'روبية سريلانكية',
  'country_in': 'الهند',
  'country_ae': 'الإمارات',
  'country_sa': 'السعودية',
  'country_qa': 'قطر',
  'country_kw': 'الكويت',
  'country_om': 'عُمان',
  'country_bh': 'البحرين',
  'country_us': 'الولايات المتحدة',
  'country_gb': 'المملكة المتحدة',
  'country_au': 'أستراليا',
  'country_sg': 'سنغافورة',
  'country_my': 'ماليزيا',
  'country_de': 'ألمانيا',
  'lang_en': 'الإنجليزية',
  'lang_ar': 'العربية',
  'lang_ml': 'المالايالامية',
  'lang_ta': 'التاميلية',
  'lang_kn': 'الكنادية',
  'lang_hi': 'الهندية',
  'account': 'الحساب',
  'askNameTitle': 'بماذا نناديك؟',
  'importDone': 'وصلت جمعية 5K الخاصة بك.',
  'importTitle': 'أحضر جمعية 5K الخاصة بك',
  'importButton': 'إحضار',
  'newChit': 'جمعية جديدة',
  'noChits': 'لا توجد جمعيات بعد.',
  'startChit': 'ابدأ جمعية',
  'yourChits': 'جمعياتك',
  'roleAdmin': 'مشرف',
  'monthOfTotal': 'الشهر {n} من {total}، {label}',
  'ofAmount': 'من {amount}',
  'paidOfTotal': 'دفع {paid} من {total}',
  'collectionNote': 'التحصيل {day} {month}، {note}',
  'takesPotName': 'يستلم الجمعية: {name}',
  'yourName': 'اسمك',
  'save': 'حفظ',
  'cancel': 'إلغاء',
  'close': 'إغلاق',
  'yes': 'نعم',
  'tryAgain': 'حاول مرة أخرى',
  'language': 'اللغة',
  'languagePhone': 'لغة الهاتف',
  'agoJustNow': 'الآن',
  'agoMinutes': 'قبل {n} دقيقة',
  'agoToday': 'اليوم، {time}',
  'agoYesterday': 'أمس، {time}',
  'am': 'ص',
  'pm': 'م',
  'andJoin': '{first} و{last}',
  'slotN': 'السهم {n}',
  'someone': 'شخص ما',
  'shareHalf': 'نصف سهم',
  'shareThird': 'ثلث سهم',
  'shareQuarter': 'ربع سهم',
  'shareAmount': 'حصة {amount}',
  'noteInDays': 'بعد {n} أيام',
  'noteTomorrow': 'غدًا',
  'noteToday': 'اليوم',
  'noteDaysLeft': 'باقي {n} أيام للدفع',
  'noteLastDayTomorrow': 'آخر يوم غدًا',
  'notePayToday': 'الدفع قبل منتصف الليل اليوم',
  'noteDeadlinePassed': 'انتهى الموعد',
  'errSessionEnded': 'انتهى تسجيل دخولك. سجّل الدخول مرة أخرى.',
  'errSignInAgain': 'سجّل الدخول مرة أخرى.',
  'errOffline': 'غير متصل.',
  'errTimeout': 'تأخر الخادم في الرد. تحقق من الاتصال وحاول مرة أخرى.',
  'errNoConnection': 'لا يوجد اتصال. تحقق من الإنترنت وحاول مرة أخرى.',
  'errServer': 'حدثت مشكلة في خادم Kuree. حاول مرة أخرى بعد دقيقة.',
  'errStatus': 'حدث خطأ ما ({status}).',
  'errNotOnWhatsApp': 'هذا الرقم غير موجود على WhatsApp.',
  'errCouldNotSend': 'لم نتمكن من إرسال الرمز. حاول مرة أخرى بعد دقيقة.',
  'errTooMany': 'محاولات كثيرة. انتظر دقيقة وحاول مرة أخرى.',
  'errWrongCode': 'هذا الرمز خاطئ أو انتهت صلاحيته. اطلب رمزًا جديدًا.',
  'errPasswordMismatch': 'البريد الإلكتروني وكلمة المرور غير متطابقين.',
  'errPhoneCountry': 'أدخل رقم WhatsApp مع رمز الدولة.',
  'errEmailLooksWrong': 'يبدو أن هذا البريد الإلكتروني غير صحيح.',
  'errSignInNotFinished': 'لم يكتمل تسجيل الدخول. حاول مرة أخرى.',
  'errFile': 'تعذّر إنشاء الملف الآن. حاول مرة أخرى بعد دقيقة.',
  'msgReminder': 'مرحبًا {name}، تذكير: دفعتك في {chit} بمبلغ {amount} عن الشهر {n} ({label}) مستحقة قبل منتصف ليل يوم {day}.',
  'msgReminderFrom': 'مرحبًا {name}، تذكير من {group}: دفعتك في {chit} بمبلغ {amount} عن الشهر {n} ({label}) مستحقة قبل منتصف ليل يوم {day}.',
  'msgFineAfter': ' بعد ذلك توجد غرامة تأخير قدرها {fine}.',
  'msgThanks': ' شكرًا لك.',
  'msgPaidHead': '{month} : تم الدفع',
  'msgDueHead': '{month} : لم يدفع بعد',
  'msgDrawResult': '{chit}، الشهر {n} ({label})\nاختارت القارورة: {slot}. {name}\nيستلم مبلغ الجمعية {pot}.\nكان في القارورة {count} أسماء. تم السحب {when}.',
  'savedMembersSee': 'تم الحفظ. يراه الأعضاء الآن.',
  'conflictTitle': 'شخص آخر حفظ هذا',
  'conflictText': 'حفظ مشرف آخر هذه الجمعية قبل لحظات. أعد التحميل لترى تغييره، ثم أجرِ تغييرك مرة أخرى.',
  'reload': 'إعادة التحميل',
  'nobodyYet': 'لا أحد بعد',
  'clearChoice': 'إلغاء الاختيار',
  'takesPotInMonth': 'يستلم الجمعية في الشهر {n}',
  'allSlotsTaken': 'كل الأسهم استلمت الجمعية بالفعل.',
  'onlyOneLeft': 'لم يبقَ إلا {name}، فلا حاجة للسحب. استخدم اختيار.',
  'savedMonthGoesTo': 'تم الحفظ. الشهر {n} من نصيب {name}.',
  'drawDonePressSave': 'تم السحب. اضغط حفظ لنشره.',
  'numberAddedPressSave': 'تمت إضافة الرقم. اضغط حفظ للاحتفاظ به.',
  'slotsFromNames': 'أضف الأسماء في الأسفل. كل اسم سهم واحد، والجمعية شهر واحد لكل سهم.',
  'fineChip': 'غرامة التأخير {fine}',
  'fineEach': '{fine} لكل دفعة متأخرة',
  'addLateFine': 'أضف غرامة تأخير',
  'fineSheetText': 'تُضاف إلى جمعية ذلك الشهر عن كل دفعة متأخرة. الغرامات المسجلة من قبل تبقى بمبلغها.',
  'fineChangedPressSave': 'غرامة التأخير الآن {fine}. اضغط حفظ للاحتفاظ بها.',
  'fineOffPressSave': 'لا غرامة تأخير من الآن. اضغط حفظ للاحتفاظ بذلك.',
  'newLinkTitle': 'إنشاء رابط جديد؟',
  'newLinkText': 'يتوقف الرابط القديم عن العمل فورًا. شارك الرابط الجديد في المجموعة.',
  'newLinkYes': 'إنشاء رابط جديد',
  'makingSheet': 'جارٍ إعداد جدول البيانات…',
  'saveFirstTitle': 'الحفظ أولًا؟',
  'saveFirstText': 'احفظ تغييرات هذا الشهر قبل تعديل الجمعية.',
  'deleteChitTitle': 'حذف {name}؟',
  'deleteChitText': 'ستُحذف الجمعية وسجلها ورابط الأعضاء نهائيًا. لا يمكن التراجع عن هذا.',
  'delete': 'حذف',
  'membersLink': 'رابط الأعضاء',
  'membersLinkSub': 'شاركه في المجموعة',
  'drawRest': 'سحب الباقي',
  'drawRestSub': 'خلط كل الشهور المتبقية',
  'spreadsheet': 'جدول البيانات',
  'spreadsheetSub': 'كل شهر، كل عضو',
  'history': 'السجل',
  'historySub': 'كل النسخ السابقة',
  'admins': 'المشرفون',
  'adminsSub': 'من يدير هذه الجمعية',
  'editChit': 'تعديل الجمعية',
  'editChitSub': 'الاسم، المبالغ، العملة، التواريخ، الأسهم، الأشخاص',
  'deleteChit': 'حذف الجمعية',
  'leaveTitle': 'المغادرة دون حفظ؟',
  'leaveText': 'تغييراتك على هذا الشهر لم تُحفظ بعد.',
  'leave': 'مغادرة',
  'more': 'المزيد',
  'saveChangesFirst': 'احفظ تغييراتك أولًا.',
  'historyKept': 'كل حفظ يبقى في السجل، فلا يضيع شيء.',
  'lastSavedBy': 'آخر حفظ بواسطة {name}، {when}',
  'notSavedYet': 'لم يُحفظ بعد',
  'undo': 'تراجع',
  'prevMonth': 'الشهر السابق',
  'nextMonth': 'الشهر التالي',
  'prevYear': 'السنة السابقة',
  'nextYear': 'السنة التالية',
  'monthNLabel': 'الشهر {n}، {label}',
  'collectedOf': 'تم تحصيله من {pot}',
  'collectedOfFines': 'تم تحصيله من {pot}، إضافة إلى غرامات {fines}',
  'toGo': 'باقي {n}',
  'everyonePaid': 'الجميع دفع',
  'heroCollection': 'التحصيل {day} {month}، الدفع حتى {payDay} {payMonth}: {note}',
  'month': 'الشهر',
  'settled': 'مكتمل',
  'inProgress': 'جارٍ',
  'inProgressTakes': 'جارٍ، يستلمها {name}',
  'upcoming': 'قادم',
  'upcomingTakes': 'قادم، يستلمها {name}',
  'winnerAmountFine': '{total} (مبلغ الجمعية مع غرامة {fine})',
  'pickedFromBottle': '{amount}، اختارته القارورة',
  'takesPotThisMonth': 'يستلم الجمعية هذا الشهر',
  'notDecided': 'لم يُحدد بعد',
  'bottleDraw': 'سحب القارورة',
  'choose': 'اختيار',
  'change': 'تغيير',
  'allPaid': 'الجميع دفع',
  'reminders': 'التذكيرات',
  'everyonePaidFor': 'الجميع دفع عن الشهر {n}',
  'showList': 'عرض',
  'hideList': 'إخفاء',
  'filterAll': 'الكل {n}',
  'filterDue': 'لم يدفع {n}',
  'filterPaid': 'دفع {n}',
  'tickHelp': 'اضغط علامة الصح عندما يدفع أحد. اضغط متأخر إذا دفع بعد آخر موعد.',
  'everyonePaidMonth': 'دفع الجميع عن الشهر {n}.',
  'nobodyPaidMonth': 'لم يدفع أحد عن الشهر {n} بعد.',
  'statusPaid': 'دفع {amount}',
  'statusPending': 'مستحق {amount}',
  'statusLateFine': '{status}، غرامة تأخير {fine}',
  'monthN': 'الشهر {n}',
  'semPaid': 'دفع: {name}',
  'semLate': 'غرامة تأخير، {name}',
  'lateButton': 'متأخر',
  'couldNotOpen': 'تعذّر فتح ذلك. هل WhatsApp مثبت؟',
  'copied': 'تم النسخ',
  'drawTitle': 'سحب الشهر {n}',
  'drawSubtitle': '{label}، مبلغ الجمعية {pot}',
  'savedToPhotos': 'تم الحفظ في صورك.',
  'videoFailed': 'تعذّر إنشاء الفيديو على هذا الهاتف.',
  'drawShareTitle': '{title}، سحب الشهر {n}',
  'stopDrawTitle': 'إيقاف السحب؟',
  'nothingSaved': 'لن يُحفظ شيء.',
  'stop': 'إيقاف',
  'closeUnsavedTitle': 'الإغلاق دون حفظ؟',
  'winnerNotSaved': 'لم يُحفظ المستلم بعد.',
  'slipsGoIn': '{n} أوراق تدخل القارورة، ورقة لكل سهم لم يستلم الجمعية بعد.',
  'recordHint': 'أمسك هاتفًا آخر فوق هذه الشاشة وابدأ التسجيل، ثم اضغط ابدأ السحب. يبدأ العد التنازلي من 3.',
  'musicSound': 'الموسيقى والمؤثرات الصوتية',
  'gettingReady': 'جارٍ التحضير',
  'startDraw': 'ابدأ السحب',
  'takesPotFor': 'يستلم الجمعية عن الشهر {n}، {label}.',
  'saved': 'تم الحفظ',
  'saveAsWinner': 'حفظه مستلمًا للشهر {n}',
  'makingVideo': 'جارٍ إنشاء الفيديو {pct}%',
  'shareVideo': 'مشاركة الفيديو',
  'saveVideo': 'حفظ الفيديو',
  'sendResultWa': 'إرسال النتيجة عبر WhatsApp',
  'drawGetReady': 'استعد',
  'drawStartsSoon': 'يبدأ السحب بعد لحظات',
  'drawWriting': 'كتابة كل الأسماء',
  'drawWritingSub': 'ورقة لكل سهم لم يستلم الجمعية بعد',
  'drawInto': 'إلى القارورة',
  'drawClosing': 'إغلاق القارورة',
  'drawShaking': 'الخلط',
  'drawShakingSub': 'لكل ورقة الفرصة نفسها',
  'drawPicking': 'اختيار ورقة',
  'drawFooterDrawn': '{n} أسماء في القارورة. تم السحب {when}',
  'drawFooterNow': '{n} أسماء في القارورة. {when}',
  'everyMonthTaken': 'كل الشهور من الشهر القادم لها مستلم بالفعل.',
  'drawRestIntro': '{slots} أسهم لم تستلم الجمعية بعد، على {months} شهور من {from}. كل سهم سحبة واحدة.',
  'drawRestIntroOne': '{slots} أسهم لم تستلم الجمعية بعد، على شهر واحد من {from}. كل سهم سحبة واحدة.',
  'noSlotLeft': 'لا يوجد سهم متبقٍ',
  'notPlaced': 'لم يوضع (لا يوجد شهر متبقٍ): {list}',
  'useThisOrder': 'استخدم هذا الترتيب',
  'useOrderTitle': 'استخدام هذا الترتيب؟',
  'useOrderText': 'هذا يحدد من يستلم الجمعية في {n} شهور. يمكنك تغيير أي شهر يدويًا قبل الحفظ.',
  'useIt': 'استخدمه',
  'shuffleAgain': 'اخلط مرة أخرى',
  'remindersTitle': 'التذكيرات، الشهر {n}',
  'shareListInGroup': 'شارك القائمة في المجموعة',
  'nobodyToRemind': 'الجميع دفع، فلا أحد يحتاج تذكيرًا.',
  'remindEach': 'أو راسل كل شخص على حدة. {rest}',
  'everyoneHasNumber': 'الجميع هنا لديه رقم.',
  'noNumberOne': 'شخص واحد بلا رقم بعد.',
  'noNumberMany': '{n} أشخاص بلا رقم بعد.',
  'noNumberYet': 'لا يوجد رقم بعد',
  'dueMonth': '{amount} مستحق، الشهر {n}',
  'addNumber': 'إضافة رقم',
  'sent': 'تم الإرسال',
  'remind': 'تذكير',
  'couldNotOpenWa': 'تعذّر فتح WhatsApp.',
  'numberTitle': 'رقم {name}',
  'enterWaNumber': 'أدخل رقم WhatsApp.',
  'waNumberHint': 'رقم WhatsApp',
  'numberUse': 'للتذكيرات فقط. لا يراه الأعضاء أبدًا.',
  'saveNumber': 'حفظ الرقم',
  'linkExplain': 'يفتحه الأعضاء في أي متصفح. يرون من دفع، والغرامات، ومن استلم الجمعية، وما التالي. بلا تطبيق أو تسجيل دخول، وبلا أرقام هواتف.',
  'copy': 'نسخ',
  'linkCopied': 'تم نسخ الرابط',
  'whatsapp': 'WhatsApp',
  'open': 'فتح',
  'share': 'مشاركة',
  'errNeedName': 'أعطِ الجمعية اسمًا، مثل جمعية 5K.',
  'errNeedShare': 'أدخل كم يدفع كل سهم في الشهر.',
  'errSlotName': 'السهم {n} يحتاج اسمًا.',
  'errPartsSum': 'السهم {n}: مجموع الحصص {total}، لكن السهم يدفع {share}.',
  'errPartAmount': 'السهم {n}: أدخل ما يدفعه كل شخص.',
  'errFewerSlots': 'الشهر {n} فيه دفعات أو مستلم بالفعل، لذا لا يمكن أن يكون للجمعية أقل من {n} أسهم.',
  'errTakerSlot': 'السهم {slot} استلم الجمعية في الشهر {n}، لذا تحتاج الجمعية {slot} أسهم على الأقل.',
  'errConflictEditor': 'حفظ مشرف آخر هذه الجمعية قبل لحظات. ارجع وأعد تحميلها، ثم أجرِ تغييراتك مرة أخرى.',
  'firstMonth': 'الشهر الأول',
  'shorterMonths': 'الشهور الأقصر تستخدم آخر يوم فيها',
  'currency': 'العملة',
  'sectionChit': 'الجمعية',
  'sectionMoney': 'المال',
  'sectionDates': 'التواريخ',
  'fieldName': 'الاسم',
  'nameHint': 'جمعية 5K',
  'fieldGroup': 'المجموعة',
  'groupHint': 'ريفرسايد',
  'eachSlotPays': 'يدفع كل سهم شهريًا',
  'lateFine': 'غرامة التأخير',
  'fineNone': 'لا يوجد',
  'slots': 'الأسهم',
  'fewerSlots': 'أسهم أقل',
  'moreSlots': 'أسهم أكثر',
  'potSummary': 'مبلغ الجمعية {pot} شهريًا، لمدة {n} شهور',
  'potSummaryNone': 'يستلم سهم واحد الجمعية كل شهر، لمدة {n} شهور',
  'collectionDay': 'يوم التحصيل',
  'everyMonthDay': 'يوم {day} من كل شهر',
  'lastDayToPay': 'آخر يوم للدفع',
  'byMidnight': 'يوم {day}، قبل منتصف الليل',
  'byMidnightNext': 'يوم {day} من الشهر التالي، قبل منتصف الليل',
  'oneNamePerSlot': 'اسم واحد لكل سهم',
  'numbersForReminders': 'أرقام للتذكيرات',
  'countOf': '{a} من {b}',
  'addNamesFirst': 'أضف الأسماء إلى الأسهم أولًا.',
  'numbersNote': 'الأرقام لتذكيرات WhatsApp فقط. لا تظهر أبدًا على رابط الأعضاء.',
  'startTheChit': 'ابدأ الجمعية',
  'saveChanges': 'حفظ التغييرات',
  'nameN': 'الاسم {n}',
  'remove': 'إزالة',
  'splitSlot': 'قسّم هذا السهم',
  'addPerson': 'أضف شخصًا',
  'somethingWrong': 'حدث خطأ ما. حاول مرة أخرى.',
  'enterYourWa': 'أدخل رقم WhatsApp الخاص بك.',
  'enterCode': 'أدخل الرمز المكوّن من 6 أرقام.',
  'enterEmailPassword': 'أدخل البريد الإلكتروني وكلمة المرور.',
  'subPhoneCode': 'تحقق من WhatsApp للحصول على الرمز.',
  'subEmailCode': 'تحقق من بريدك الإلكتروني للحصول على الرمز.',
  'subPhone': 'سجّل الدخول برقم WhatsApp الخاص بك.',
  'subEmail': 'سجّل الدخول ببريدك الإلكتروني.',
  'subStart': 'أدر جمعيتك من هاتفك.',
  'privacy': 'الخصوصية',
  'terms': 'الشروط',
  'continueWa': 'المتابعة عبر WhatsApp',
  'useEmailInstead': 'استخدم البريد الإلكتروني بدلًا من ذلك',
  'phoneHint': 'رقم الهاتف',
  'sendCodeWa': 'أرسل الرمز عبر WhatsApp',
  'codeSentWa': 'أرسلنا رمزًا من 6 أرقام عبر WhatsApp إلى {to}. صالح لمدة 10 دقائق.',
  'codeSentEmail': 'أرسلنا رمزًا من 6 أرقام إلى {to}. صالح لمدة 10 دقائق.',
  'signIn': 'تسجيل الدخول',
  'sendAgainIn': 'إعادة الإرسال بعد {n} ث',
  'sendAgain': 'إعادة الإرسال',
  'anotherNumber': 'رقم آخر',
  'anotherEmail': 'بريد آخر',
  'email': 'البريد الإلكتروني',
  'emailMeCode': 'أرسل لي رمزًا بالبريد',
  'useWa': 'استخدم WhatsApp',
  'usePassword': 'استخدم كلمة مرور',
  'password': 'كلمة المرور',
  'emailCodeInstead': 'أرسل لي رمزًا بالبريد بدلًا من ذلك',
  'countryCode': 'رمز الدولة',
  'signOutTitle': 'تسجيل الخروج؟',
  'signOutText': 'تبقى جمعياتك آمنة على الخادم. سجّل الدخول مرة أخرى لرؤيتها.',
  'signOut': 'تسجيل الخروج',
  'deleteAccountTitle': 'حذف حسابك؟',
  'deleteAccountText': 'سيُحذف حسابك واسمك في Kuree. الجمعيات التي تملكها تنتقل إلى المشرف التالي. الجمعيات التي تديرها وحدك تُحذف نهائيًا مع سجلها وروابط أعضائها. لا يمكن التراجع عن هذا.',
  'deleteLoginToo': 'احذف أيضًا تسجيل دخولي في SkiFi',
  'deleteLoginTooSub': 'الرقم أو البريد الذي تسجّل الدخول به. تفقده أيضًا تطبيقات SkiFi الأخرى التي تستخدمها به.',
  'deleteAccount': 'حذف الحساب',
  'deleting': 'جارٍ الحذف…',
  'noNameYet': 'لا يوجد اسم بعد',
  'edit': 'تعديل',
  'requestFeature': 'اطلب ميزة',
  'featureInbox': 'طلبات الميزات',
  'contact': 'تواصل معنا',
  'histPaid': 'الشهر {n}: دفع {a}، ثم {b}',
  'histNoTaker': 'الشهر {n} لم يكن له مستلم بعد',
  'histWentTo': 'الشهر {n} كان من نصيب {name}',
  'histFines': 'الشهر {n}: {count} غرامات تأخير',
  'histSettings': 'إعدادات مختلفة',
  'histPeople': 'أشخاص أو أسهم مختلفة',
  'histSmall': 'تغييرات صغيرة',
  'histAndMore': 'والمزيد',
  'restoreTitle': 'استعادة هذه النسخة؟',
  'restoreText': 'تعود الجمعية إلى ما تركها عليه {name}، {when}. ما تعرضه الآن يُحفظ في السجل أيضًا، فيمكنك التراجع.',
  'putItBack': 'استعادتها',
  'historyEmpty': 'لا توجد نسخ سابقة بعد. كل حفظ يضيف نسخة.',
  'savedBy': 'حفظه {name}',
  'putBack': 'استعادة',
  'addAnAdmin': 'إضافة مشرف',
  'adminAdded': 'تمت الإضافة. سيرى هذه الجمعية عند تسجيل الدخول.',
  'leaveChitTitle': 'مغادرة هذه الجمعية؟',
  'removeAdminTitle': 'إزالة {name}؟',
  'leaveChitText': 'لن تتمكن بعد ذلك من رؤيتها أو تغييرها.',
  'removeAdminText': 'لن يتمكن بعد ذلك من رؤية هذه الجمعية أو تغييرها.',
  'makeOwnerTitle': 'جعل {name} المالك؟',
  'makeOwnerText': 'سيتمكن من إضافة المشرفين وإزالتهم وحذف الجمعية. وتبقى أنت مشرفًا.',
  'makeOwner': 'جعله المالك',
  'ownsNow': '{name} يملك الجمعية الآن.',
  'addAdmin': 'إضافة مشرف',
  'adminsExplain': 'يسجّل المشرفون الدفعات ويجرون السحب ويرسلون التذكيرات. ويضيف المالك المشرفين ويزيلهم.',
  'roleOwner': 'المالك',
  'you': 'أنت',
  'leaveChit': 'مغادرة هذه الجمعية',
  'removeAdmin': 'إزالة المشرف',
  'enterTheirWa': 'أدخل رقم WhatsApp الخاص به.',
  'enterTheirEmail': 'أدخل بريده الإلكتروني.',
  'theirName': 'اسمه',
  'useEmail': 'استخدم البريد الإلكتروني',
  'adminSignInEmail': 'يسجّل الدخول إلى Kuree بهذا البريد ليرى الجمعية.',
  'adminSignInNumber': 'يسجّل الدخول إلى Kuree بهذا الرقم ليرى الجمعية.',
  'frTitle': 'اطلب ميزة',
  'frIntroTitle': 'أخبرنا بما يساعدك',
  'frIntroText': 'فكرة، أو شيء يعيقك، أو ميزة تفتقدها. نقرأ كل طلب.',
  'frFieldTitle': 'فكرتك في كلمات قليلة',
  'frFieldTitleHint': 'مثال: تذكير قبل الموعد بيوم',
  'frFieldDetails': 'أخبرنا بالمزيد (اختياري)',
  'frFieldDetailsHint': 'كيف ستستخدمها؟ ماذا يحدث اليوم؟',
  'frImportance': 'كم ستساعدك؟',
  'frNice': 'من الجيد وجودها',
  'frImportant': 'مهمة',
  'frMust': 'ضرورية',
  'frSend': 'إرسال الطلب',
  'frNeedTitle': 'أعطِ فكرتك عنوانًا قصيرًا.',
  'frThanksTitle': 'شكرًا لك!',
  'frThanksText': 'وصل طلبك إلى فريق Kuree. يمكنك متابعته أدناه.',
  'frSendAnother': 'إرسال طلب آخر',
  'frYours': 'طلباتك',
  'frNoneYet': 'ستظهر طلباتك هنا، مع قرار الفريق.',
  'frReply': 'من فريق Kuree',
  'frInboxTitle': 'طلبات الميزات',
  'frInboxEmpty': 'لا توجد طلبات هنا بعد.',
  'frAll': 'الكل',
  'frStatusNew': 'جديد',
  'frStatusPlanned': 'مخطط له',
  'frStatusDone': 'تم',
  'frStatusDeclined': 'مرفوض',
  'frChange': 'تحديث الطلب',
  'frNoteLabel': 'ملاحظة لصاحب الطلب (اختياري)',
  'frNoteHint': 'مثال: قادمة في التحديث القادم',
  'frSaved': 'تم الحفظ.',
  'frFrom': 'من',
  'frSignedOut': 'حساب محذوف',
  'tabChits': 'الجمعيات',
  'tabCollect': 'للتحصيل',
  'tabProfile': 'الملف الشخصي',
  'collectIntro': 'ما زال عليهم الدفع هذا الشهر، في كل جمعياتك.',
  'nothingToCollect': 'دفع الجميع هذا الشهر في كل الجمعيات.',
  'secPreferences': 'التفضيلات',
  'secHelp': 'المساعدة',
  'secLegal': 'قانوني',
};

const Map<String, String> _ml = {
  'month1': 'ജനുവരി',
  'month2': 'ഫെബ്രുവരി',
  'month3': 'മാർച്ച്',
  'month4': 'ഏപ്രിൽ',
  'month5': 'മേയ്',
  'month6': 'ജൂൺ',
  'month7': 'ജൂലൈ',
  'month8': 'ഓഗസ്റ്റ്',
  'month9': 'സെപ്റ്റംബർ',
  'month10': 'ഒക്ടോബർ',
  'month11': 'നവംബർ',
  'month12': 'ഡിസംബർ',
  'monthShort1': 'ജനു',
  'monthShort2': 'ഫെബ്രു',
  'monthShort3': 'മാർ',
  'monthShort4': 'ഏപ്രി',
  'monthShort5': 'മേയ്',
  'monthShort6': 'ജൂൺ',
  'monthShort7': 'ജൂലൈ',
  'monthShort8': 'ഓഗ',
  'monthShort9': 'സെപ്റ്റ',
  'monthShort10': 'ഒക്ടോ',
  'monthShort11': 'നവം',
  'monthShort12': 'ഡിസം',
  'currencyINR': 'ഇന്ത്യൻ രൂപ',
  'currencyAED': 'യുഎഇ ദിർഹം',
  'currencySAR': 'സൗദി റിയാൽ',
  'currencyQAR': 'ഖത്തർ റിയാൽ',
  'currencyKWD': 'കുവൈത്ത് ദിനാർ',
  'currencyOMR': 'ഒമാൻ റിയാൽ',
  'currencyBHD': 'ബഹ്റൈൻ ദിനാർ',
  'currencyUSD': 'യുഎസ് ഡോളർ',
  'currencyGBP': 'ബ്രിട്ടീഷ് പൗണ്ട്',
  'currencyEUR': 'യൂറോ',
  'currencySGD': 'സിംഗപ്പൂർ ഡോളർ',
  'currencyMYR': 'മലേഷ്യൻ റിംഗിറ്റ്',
  'currencyLKR': 'ശ്രീലങ്കൻ രൂപ',
  'country_in': 'ഇന്ത്യ',
  'country_ae': 'യുഎഇ',
  'country_sa': 'സൗദി അറേബ്യ',
  'country_qa': 'ഖത്തർ',
  'country_kw': 'കുവൈത്ത്',
  'country_om': 'ഒമാൻ',
  'country_bh': 'ബഹ്റൈൻ',
  'country_us': 'അമേരിക്ക',
  'country_gb': 'യുണൈറ്റഡ് കിങ്ഡം',
  'country_au': 'ഓസ്ട്രേലിയ',
  'country_sg': 'സിംഗപ്പൂർ',
  'country_my': 'മലേഷ്യ',
  'country_de': 'ജർമ്മനി',
  'lang_en': 'ഇംഗ്ലീഷ്',
  'lang_ar': 'അറബിക്',
  'lang_ml': 'മലയാളം',
  'lang_ta': 'തമിഴ്',
  'lang_kn': 'കന്നഡ',
  'lang_hi': 'ഹിന്ദി',
  'account': 'അക്കൗണ്ട്',
  'askNameTitle': 'നിങ്ങളെ എന്ത് പേരിൽ വിളിക്കണം?',
  'importDone': 'നിങ്ങളുടെ 5K ചിട്ടി എത്തി.',
  'importTitle': 'നിങ്ങളുടെ 5K ചിട്ടി കൊണ്ടുവരൂ',
  'importButton': 'കൊണ്ടുവരിക',
  'newChit': 'പുതിയ ചിട്ടി',
  'noChits': 'ഇതുവരെ ചിട്ടികളൊന്നുമില്ല.',
  'startChit': 'ഒരു ചിട്ടി തുടങ്ങൂ',
  'yourChits': 'നിങ്ങളുടെ ചിട്ടികൾ',
  'roleAdmin': 'അഡ്മിൻ',
  'monthOfTotal': 'മാസം {n} / {total}, {label}',
  'ofAmount': '{amount}-ൽ',
  'paidOfTotal': '{total}-ൽ {paid} പേർ അടച്ചു',
  'collectionNote': 'പിരിവ് {day} {month}, {note}',
  'takesPotName': 'ചിട്ടി കിട്ടുന്നത്: {name}',
  'yourName': 'നിങ്ങളുടെ പേര്',
  'save': 'സേവ് ചെയ്യുക',
  'cancel': 'റദ്ദാക്കുക',
  'close': 'അടയ്ക്കുക',
  'yes': 'അതെ',
  'tryAgain': 'വീണ്ടും ശ്രമിക്കുക',
  'language': 'ഭാഷ',
  'languagePhone': 'ഫോണിലെ ഭാഷ',
  'agoJustNow': 'ഇപ്പോൾ',
  'agoMinutes': '{n} മിനിറ്റ് മുമ്പ്',
  'agoToday': 'ഇന്ന്, {time}',
  'agoYesterday': 'ഇന്നലെ, {time}',
  'am': 'AM',
  'pm': 'PM',
  'andJoin': '{first}, {last}',
  'slotN': 'സ്ലോട്ട് {n}',
  'someone': 'ഒരാൾ',
  'shareHalf': '½ പങ്ക്',
  'shareThird': '⅓ പങ്ക്',
  'shareQuarter': '¼ പങ്ക്',
  'shareAmount': '{amount} പങ്ക്',
  'noteInDays': '{n} ദിവസം കൂടി',
  'noteTomorrow': 'നാളെ',
  'noteToday': 'ഇന്ന്',
  'noteDaysLeft': 'അടയ്ക്കാൻ {n} ദിവസം കൂടി',
  'noteLastDayTomorrow': 'അവസാന ദിവസം നാളെ',
  'notePayToday': 'ഇന്ന് അർദ്ധരാത്രിക്കകം അടയ്ക്കണം',
  'noteDeadlinePassed': 'അവസാന തീയതി കഴിഞ്ഞു',
  'errSessionEnded': 'നിങ്ങളുടെ സൈൻ ഇൻ കാലാവധി കഴിഞ്ഞു. വീണ്ടും സൈൻ ഇൻ ചെയ്യുക.',
  'errSignInAgain': 'വീണ്ടും സൈൻ ഇൻ ചെയ്യുക.',
  'errOffline': 'ഓഫ്‌ലൈൻ.',
  'errTimeout': 'സെർവർ മറുപടി നൽകാൻ വൈകി. കണക്ഷൻ നോക്കി വീണ്ടും ശ്രമിക്കുക.',
  'errNoConnection': 'കണക്ഷൻ ഇല്ല. ഇന്റർനെറ്റ് നോക്കി വീണ്ടും ശ്രമിക്കുക.',
  'errServer': 'Kuree സെർവറിൽ ഒരു പ്രശ്നം. ഒരു മിനിറ്റ് കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കുക.',
  'errStatus': 'എന്തോ പിഴവ് സംഭവിച്ചു ({status}).',
  'errNotOnWhatsApp': 'ഈ നമ്പർ WhatsApp-ൽ ഇല്ല.',
  'errCouldNotSend': 'കോഡ് അയയ്ക്കാൻ കഴിഞ്ഞില്ല. ഒരു മിനിറ്റ് കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കുക.',
  'errTooMany': 'ഒരുപാട് ശ്രമങ്ങൾ. ഒരു മിനിറ്റ് കാത്തിരുന്ന് വീണ്ടും ശ്രമിക്കുക.',
  'errWrongCode': 'ആ കോഡ് തെറ്റാണ്, അല്ലെങ്കിൽ കാലാവധി കഴിഞ്ഞു. പുതിയൊരെണ്ണം ചോദിക്കുക.',
  'errPasswordMismatch': 'ആ ഇമെയിലും പാസ്‌വേഡും ഒത്തുപോകുന്നില്ല.',
  'errPhoneCountry': 'രാജ്യ കോഡ് ചേർത്ത് നിങ്ങളുടെ WhatsApp നമ്പർ നൽകുക.',
  'errEmailLooksWrong': 'ആ ഇമെയിൽ ശരിയാണെന്ന് തോന്നുന്നില്ല.',
  'errSignInNotFinished': 'സൈൻ ഇൻ പൂർത്തിയായില്ല. വീണ്ടും ശ്രമിക്കുക.',
  'errFile': 'ഇപ്പോൾ ഫയൽ ഉണ്ടാക്കാൻ കഴിഞ്ഞില്ല. ഒരു മിനിറ്റ് കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കുക.',
  'msgReminder': 'നമസ്കാരം {name}, ഒരു ഓർമ്മപ്പെടുത്തൽ: {chit} മാസം {n} ({label}) തവണയായ {amount}, {day}-ാം തീയതി അർദ്ധരാത്രിക്കകം അടയ്ക്കണം.',
  'msgReminderFrom': 'നമസ്കാരം {name}, {group} അയയ്ക്കുന്ന ഓർമ്മപ്പെടുത്തൽ: {chit} മാസം {n} ({label}) തവണയായ {amount}, {day}-ാം തീയതി അർദ്ധരാത്രിക്കകം അടയ്ക്കണം.',
  'msgFineAfter': ' അതിനു ശേഷം {fine} പിഴയുണ്ട്.',
  'msgThanks': ' നന്ദി.',
  'msgPaidHead': '{month} : അടച്ചവർ',
  'msgDueHead': '{month} : ഇനിയും അടയ്ക്കാത്തവർ',
  'msgDrawResult': '{chit}, മാസം {n} ({label})\nകുപ്പിയിൽ നിന്ന് കിട്ടിയത്: {slot}. {name}\n{pot} ചിട്ടിത്തുക ഇവർക്ക്.\nകുപ്പിയിൽ {count} പേരുകൾ ഉണ്ടായിരുന്നു. നറുക്കെടുത്തത് {when}.',
  'savedMembersSee': 'സേവ് ചെയ്തു. അംഗങ്ങൾക്ക് ഇപ്പോൾ കാണാം.',
  'conflictTitle': 'മറ്റൊരാൾ ഇത് സേവ് ചെയ്തു',
  'conflictText': 'മറ്റൊരു അഡ്മിൻ അൽപം മുമ്പ് ഈ ചിട്ടി സേവ് ചെയ്തു. അവരുടെ മാറ്റം കാണാൻ റീലോഡ് ചെയ്യുക, എന്നിട്ട് നിങ്ങളുടേത് വീണ്ടും ചെയ്യുക.',
  'reload': 'റീലോഡ്',
  'nobodyYet': 'ഇതുവരെ ആരുമില്ല',
  'clearChoice': 'തിരഞ്ഞെടുപ്പ് മാറ്റുക',
  'takesPotInMonth': 'മാസം {n}-ൽ ചിട്ടി കിട്ടുന്നത്',
  'allSlotsTaken': 'എല്ലാ സ്ലോട്ടുകൾക്കും ചിട്ടി കിട്ടിക്കഴിഞ്ഞു.',
  'onlyOneLeft': '{name} മാത്രമേ ബാക്കിയുള്ളൂ, അതിനാൽ നറുക്കെടുക്കാനില്ല. തിരഞ്ഞെടുക്കുക ഉപയോഗിക്കൂ.',
  'savedMonthGoesTo': 'സേവ് ചെയ്തു. മാസം {n} {name}-ന്.',
  'drawDonePressSave': 'നറുക്കെടുപ്പ് കഴിഞ്ഞു. പ്രസിദ്ധീകരിക്കാൻ സേവ് അമർത്തുക.',
  'numberAddedPressSave': 'നമ്പർ ചേർത്തു. സൂക്ഷിക്കാൻ സേവ് അമർത്തുക.',
  'slotsFromNames': 'താഴെ പേരുകൾ ചേർക്കുക. ഓരോ പേരും ഒരു സ്ലോട്ടാണ്, ഓരോ സ്ലോട്ടിനും ഒരു മാസം.',
  'fineChip': 'വൈകിയതിനുള്ള പിഴ {fine}',
  'fineEach': 'വൈകിയ ഓരോ അടവിനും {fine}',
  'addLateFine': 'വൈകിയതിനുള്ള പിഴ ചേർക്കുക',
  'fineSheetText': 'വൈകിയ ഓരോ അടവിനും ആ മാസത്തെ ചിട്ടിത്തുകയിൽ ചേരും. മുമ്പ് രേഖപ്പെടുത്തിയ പിഴകൾ അതേ തുകയിൽ തുടരും.',
  'fineChangedPressSave': 'വൈകിയതിനുള്ള പിഴ ഇപ്പോൾ {fine}. സൂക്ഷിക്കാൻ സേവ് അമർത്തുക.',
  'fineOffPressSave': 'ഇനി മുതൽ വൈകിയതിനുള്ള പിഴ ഇല്ല. സൂക്ഷിക്കാൻ സേവ് അമർത്തുക.',
  'newLinkTitle': 'പുതിയ ലിങ്ക് ഉണ്ടാക്കണോ?',
  'newLinkText': 'പഴയ ലിങ്ക് ഉടൻ പ്രവർത്തിക്കാതാകും. പുതിയത് ഗ്രൂപ്പിൽ പങ്കിടുക.',
  'newLinkYes': 'പുതിയ ലിങ്ക് ഉണ്ടാക്കുക',
  'makingSheet': 'സ്പ്രെഡ്ഷീറ്റ് തയ്യാറാക്കുന്നു…',
  'saveFirstTitle': 'ആദ്യം സേവ് ചെയ്യണോ?',
  'saveFirstText': 'ചിട്ടി എഡിറ്റ് ചെയ്യുന്നതിനു മുമ്പ് ഈ മാസത്തെ മാറ്റങ്ങൾ സേവ് ചെയ്യുക.',
  'deleteChitTitle': '{name} ഡിലീറ്റ് ചെയ്യണോ?',
  'deleteChitText': 'ചിട്ടിയും അതിന്റെ ചരിത്രവും അംഗങ്ങളുടെ ലിങ്കും എന്നേക്കുമായി ഡിലീറ്റ് ആകും. ഇത് തിരിച്ചെടുക്കാനാവില്ല.',
  'delete': 'ഡിലീറ്റ് ചെയ്യുക',
  'membersLink': 'അംഗങ്ങളുടെ ലിങ്ക്',
  'membersLinkSub': 'ഗ്രൂപ്പിൽ പങ്കിടുക',
  'drawRest': 'ബാക്കി നറുക്കെടുക്കുക',
  'drawRestSub': 'ബാക്കിയുള്ള എല്ലാ മാസങ്ങളും കുലുക്കിയെടുക്കുക',
  'spreadsheet': 'സ്പ്രെഡ്ഷീറ്റ്',
  'spreadsheetSub': 'എല്ലാ മാസവും, എല്ലാ അംഗങ്ങളും',
  'history': 'ചരിത്രം',
  'historySub': 'മുമ്പത്തെ എല്ലാ പതിപ്പുകളും',
  'admins': 'അഡ്മിൻമാർ',
  'adminsSub': 'ഈ ചിട്ടി നടത്തുന്നവർ',
  'editChit': 'ചിട്ടി എഡിറ്റ് ചെയ്യുക',
  'editChitSub': 'പേര്, തുകകൾ, കറൻസി, തീയതികൾ, സ്ലോട്ടുകൾ, ആളുകൾ',
  'deleteChit': 'ചിട്ടി ഡിലീറ്റ് ചെയ്യുക',
  'leaveTitle': 'സേവ് ചെയ്യാതെ പോകണോ?',
  'leaveText': 'ഈ മാസത്തെ നിങ്ങളുടെ മാറ്റങ്ങൾ ഇതുവരെ സേവ് ചെയ്തിട്ടില്ല.',
  'leave': 'പോകുക',
  'more': 'കൂടുതൽ',
  'saveChangesFirst': 'ആദ്യം മാറ്റങ്ങൾ സേവ് ചെയ്യുക.',
  'historyKept': 'ഓരോ സേവും ചരിത്രത്തിൽ സൂക്ഷിക്കും, ഒന്നും നഷ്ടമാകില്ല.',
  'lastSavedBy': 'അവസാനം സേവ് ചെയ്തത് {name}, {when}',
  'notSavedYet': 'ഇതുവരെ സേവ് ചെയ്തിട്ടില്ല',
  'undo': 'പഴയപടിയാക്കുക',
  'prevMonth': 'മുൻ മാസം',
  'nextMonth': 'അടുത്ത മാസം',
  'prevYear': 'മുൻ വർഷം',
  'nextYear': 'അടുത്ത വർഷം',
  'monthNLabel': 'മാസം {n}, {label}',
  'collectedOf': '{pot}-ൽ പിരിഞ്ഞത്',
  'collectedOfFines': '{pot}-ൽ പിരിഞ്ഞത്, കൂടാതെ {fines} പിഴ',
  'toGo': '{n} പേർ ബാക്കി',
  'everyonePaid': 'എല്ലാവരും അടച്ചു',
  'heroCollection': 'പിരിവ് {day} {month}, {payDay} {payMonth}-നകം അടയ്ക്കണം: {note}',
  'month': 'മാസം',
  'settled': 'തീർന്നു',
  'inProgress': 'നടക്കുന്നു',
  'inProgressTakes': 'നടക്കുന്നു, ചിട്ടി {name}-ന്',
  'upcoming': 'വരാനിരിക്കുന്നു',
  'upcomingTakes': 'വരാനിരിക്കുന്നു, ചിട്ടി {name}-ന്',
  'winnerAmountFine': '{total} (ചിട്ടിത്തുകയും {fine} പിഴയും)',
  'pickedFromBottle': '{amount}, കുപ്പിയിൽ നിന്ന് എടുത്തത്',
  'takesPotThisMonth': 'ഈ മാസം ചിട്ടി കിട്ടുന്നത്',
  'notDecided': 'ഇതുവരെ തീരുമാനിച്ചിട്ടില്ല',
  'bottleDraw': 'കുപ്പി നറുക്ക്',
  'choose': 'തിരഞ്ഞെടുക്കുക',
  'change': 'മാറ്റുക',
  'allPaid': 'എല്ലാം അടച്ചു',
  'reminders': 'ഓർമ്മിപ്പിക്കൽ',
  'everyonePaidFor': 'മാസം {n}-ന് എല്ലാവരും അടച്ചു',
  'showList': 'കാണിക്കുക',
  'hideList': 'മറയ്ക്കുക',
  'filterAll': 'എല്ലാം {n}',
  'filterDue': 'അടയ്ക്കാൻ {n}',
  'filterPaid': 'അടച്ചത് {n}',
  'tickHelp': 'ആരെങ്കിലും അടയ്ക്കുമ്പോൾ ടിക്ക് അമർത്തുക. അവസാന തീയതിക്കു ശേഷമാണ് അടച്ചതെങ്കിൽ വൈകി അമർത്തുക.',
  'everyonePaidMonth': 'മാസം {n}-ന് എല്ലാവരും അടച്ചു.',
  'nobodyPaidMonth': 'മാസം {n}-ന് ഇതുവരെ ആരും അടച്ചിട്ടില്ല.',
  'statusPaid': 'അടച്ചു {amount}',
  'statusPending': 'അടയ്ക്കാനുണ്ട് {amount}',
  'statusLateFine': '{status}, പിഴ {fine}',
  'monthN': 'മാസം {n}',
  'semPaid': 'അടച്ചു: {name}',
  'semLate': 'വൈകിയതിനുള്ള പിഴ, {name}',
  'lateButton': 'വൈകി',
  'couldNotOpen': 'അത് തുറക്കാൻ കഴിഞ്ഞില്ല. WhatsApp ഫോണിലുണ്ടോ?',
  'copied': 'കോപ്പി ചെയ്തു',
  'drawTitle': 'മാസം {n} നറുക്കെടുപ്പ്',
  'drawSubtitle': '{label}, ചിട്ടിത്തുക {pot}',
  'savedToPhotos': 'ഫോട്ടോകളിൽ സേവ് ചെയ്തു.',
  'videoFailed': 'ഈ ഫോണിൽ വീഡിയോ ഉണ്ടാക്കാൻ കഴിഞ്ഞില്ല.',
  'drawShareTitle': '{title}, മാസം {n} നറുക്കെടുപ്പ്',
  'stopDrawTitle': 'നറുക്കെടുപ്പ് നിർത്തണോ?',
  'nothingSaved': 'ഒന്നും സേവ് ചെയ്യില്ല.',
  'stop': 'നിർത്തുക',
  'closeUnsavedTitle': 'സേവ് ചെയ്യാതെ അടയ്ക്കണോ?',
  'winnerNotSaved': 'ചിട്ടി കിട്ടിയ ആളെ ഇതുവരെ സേവ് ചെയ്തിട്ടില്ല.',
  'slipsGoIn': '{n} കുറിപ്പുകൾ കുപ്പിയിലേക്ക്, ഇനിയും ചിട്ടി കിട്ടാനുള്ള ഓരോ സ്ലോട്ടിനും ഒന്ന്.',
  'recordHint': 'മറ്റൊരു ഫോൺ ഈ സ്ക്രീനിനു മുകളിൽ പിടിച്ച് റെക്കോർഡ് ചെയ്യാൻ തുടങ്ങൂ, എന്നിട്ട് നറുക്കെടുപ്പ് തുടങ്ങുക അമർത്തൂ. 3-ൽ നിന്ന് എണ്ണിത്തുടങ്ങും.',
  'musicSound': 'സംഗീതവും ശബ്ദങ്ങളും',
  'gettingReady': 'തയ്യാറാകുന്നു',
  'startDraw': 'നറുക്കെടുപ്പ് തുടങ്ങുക',
  'takesPotFor': 'മാസം {n}, {label}: ചിട്ടി ഇവർക്ക്.',
  'saved': 'സേവ് ചെയ്തു',
  'saveAsWinner': 'മാസം {n}-ലെ ചിട്ടിക്കാരനായി സേവ് ചെയ്യുക',
  'makingVideo': 'വീഡിയോ ഉണ്ടാക്കുന്നു {pct}%',
  'shareVideo': 'വീഡിയോ പങ്കിടുക',
  'saveVideo': 'വീഡിയോ സേവ് ചെയ്യുക',
  'sendResultWa': 'ഫലം WhatsApp-ൽ അയയ്ക്കുക',
  'drawGetReady': 'തയ്യാറാകൂ',
  'drawStartsSoon': 'നറുക്കെടുപ്പ് ഉടൻ തുടങ്ങും',
  'drawWriting': 'എല്ലാ പേരുകളും എഴുതുന്നു',
  'drawWritingSub': 'ചിട്ടി കിട്ടാനുള്ള ഓരോ സ്ലോട്ടിനും ഒരു കുറിപ്പ്',
  'drawInto': 'കുപ്പിയിലേക്ക്',
  'drawClosing': 'കുപ്പി അടയ്ക്കുന്നു',
  'drawShaking': 'കുലുക്കുന്നു',
  'drawShakingSub': 'എല്ലാ കുറിപ്പിനും ഒരേ സാധ്യത',
  'drawPicking': 'ഒന്ന് എടുക്കുന്നു',
  'drawFooterDrawn': 'കുപ്പിയിൽ {n} പേരുകൾ. നറുക്കെടുത്തത് {when}',
  'drawFooterNow': 'കുപ്പിയിൽ {n} പേരുകൾ. {when}',
  'everyMonthTaken': 'അടുത്ത മാസം മുതലുള്ള എല്ലാ മാസത്തിനും ചിട്ടി കിട്ടുന്നയാൾ ഇതിനകമുണ്ട്.',
  'drawRestIntro': 'ഇനിയും ചിട്ടി കിട്ടാനുള്ളത് {slots} സ്ലോട്ടുകൾ, {from} മുതൽ {months} മാസങ്ങളിലായി. ഓരോ സ്ലോട്ടും ഒരു നറുക്ക്.',
  'drawRestIntroOne': 'ഇനിയും ചിട്ടി കിട്ടാനുള്ളത് {slots} സ്ലോട്ടുകൾ, {from} മുതൽ 1 മാസത്തേക്ക്. ഓരോ സ്ലോട്ടും ഒരു നറുക്ക്.',
  'noSlotLeft': 'സ്ലോട്ട് ബാക്കിയില്ല',
  'notPlaced': 'ഉൾപ്പെടുത്താനായില്ല (മാസം ബാക്കിയില്ല): {list}',
  'useThisOrder': 'ഈ ക്രമം ഉപയോഗിക്കുക',
  'useOrderTitle': 'ഈ ക്രമം ഉപയോഗിക്കണോ?',
  'useOrderText': 'ഇത് {n} മാസങ്ങളിലെ ചിട്ടി ആർക്കെന്ന് നിശ്ചയിക്കും. സേവ് ചെയ്യുന്നതിനു മുമ്പ് ഏതു മാസവും കൈകൊണ്ട് മാറ്റാം.',
  'useIt': 'ഉപയോഗിക്കുക',
  'shuffleAgain': 'വീണ്ടും കുലുക്കുക',
  'remindersTitle': 'ഓർമ്മപ്പെടുത്തലുകൾ, മാസം {n}',
  'shareListInGroup': 'ലിസ്റ്റ് ഗ്രൂപ്പിൽ പങ്കിടുക',
  'nobodyToRemind': 'എല്ലാവരും അടച്ചു, ഓർമ്മിപ്പിക്കാൻ ആരുമില്ല.',
  'remindEach': 'അല്ലെങ്കിൽ ഓരോരുത്തർക്കും മെസേജ് അയയ്ക്കുക. {rest}',
  'everyoneHasNumber': 'ഇവിടെ എല്ലാവർക്കും നമ്പർ ഉണ്ട്.',
  'noNumberOne': '1 ആൾക്ക് ഇതുവരെ നമ്പർ ഇല്ല.',
  'noNumberMany': '{n} പേർക്ക് ഇതുവരെ നമ്പർ ഇല്ല.',
  'noNumberYet': 'ഇതുവരെ നമ്പർ ഇല്ല',
  'dueMonth': '{amount} അടയ്ക്കാനുണ്ട്, മാസം {n}',
  'addNumber': 'നമ്പർ ചേർക്കുക',
  'sent': 'അയച്ചു',
  'remind': 'ഓർമ്മിപ്പിക്കുക',
  'couldNotOpenWa': 'WhatsApp തുറക്കാൻ കഴിഞ്ഞില്ല.',
  'numberTitle': '{name}-ന്റെ നമ്പർ',
  'enterWaNumber': 'WhatsApp നമ്പർ നൽകുക.',
  'waNumberHint': 'WhatsApp നമ്പർ',
  'numberUse': 'ഓർമ്മപ്പെടുത്തലുകൾക്ക് മാത്രം. അംഗങ്ങൾ ഇത് ഒരിക്കലും കാണില്ല.',
  'saveNumber': 'നമ്പർ സേവ് ചെയ്യുക',
  'linkExplain': 'അംഗങ്ങൾക്ക് ഇത് ഏതു ബ്രൗസറിലും തുറക്കാം. ആര് അടച്ചു, പിഴകൾ, ആർക്ക് ചിട്ടി കിട്ടി, അടുത്തത് എന്ത് എന്നിവ കാണാം. ആപ്പോ സൈൻ ഇനോ വേണ്ട, ഫോൺ നമ്പറുകൾ കാണിക്കില്ല.',
  'copy': 'കോപ്പി',
  'linkCopied': 'ലിങ്ക് കോപ്പി ചെയ്തു',
  'whatsapp': 'WhatsApp',
  'open': 'തുറക്കുക',
  'share': 'പങ്കിടുക',
  'errNeedName': 'ചിട്ടിക്ക് ഒരു പേര് നൽകുക, ഉദാഹരണത്തിന് 5K ചിട്ടി.',
  'errNeedShare': 'ഓരോ സ്ലോട്ടും മാസം എത്ര അടയ്ക്കണമെന്ന് നൽകുക.',
  'errSlotName': 'സ്ലോട്ട് {n}-ന് ഒരു പേര് വേണം.',
  'errPartsSum': 'സ്ലോട്ട് {n}: പങ്കുകൾ ചേർത്താൽ {total}, പക്ഷേ ഒരു സ്ലോട്ട് അടയ്ക്കുന്നത് {share}.',
  'errPartAmount': 'സ്ലോട്ട് {n}: ഓരോരുത്തരും അടയ്ക്കുന്ന തുക നൽകുക.',
  'errFewerSlots': 'മാസം {n}-ൽ ഇതിനകം അടവുകളോ ചിട്ടി കിട്ടിയ ആളോ ഉണ്ട്, അതിനാൽ ചിട്ടിക്ക് {n}-ൽ കുറവ് സ്ലോട്ടുകൾ പറ്റില്ല.',
  'errTakerSlot': 'സ്ലോട്ട് {slot}-ന് മാസം {n}-ൽ ചിട്ടി കിട്ടി, അതിനാൽ ചിട്ടിക്ക് കുറഞ്ഞത് {slot} സ്ലോട്ടുകൾ വേണം.',
  'errConflictEditor': 'മറ്റൊരു അഡ്മിൻ അൽപം മുമ്പ് ഈ ചിട്ടി സേവ് ചെയ്തു. തിരികെ പോയി റീലോഡ് ചെയ്ത്, നിങ്ങളുടെ മാറ്റങ്ങൾ വീണ്ടും ചെയ്യുക.',
  'firstMonth': 'ആദ്യ മാസം',
  'shorterMonths': 'ദിവസം കുറഞ്ഞ മാസങ്ങളിൽ അവസാന ദിവസം',
  'currency': 'കറൻസി',
  'sectionChit': 'ചിട്ടി',
  'sectionMoney': 'പണം',
  'sectionDates': 'തീയതികൾ',
  'fieldName': 'പേര്',
  'nameHint': '5K ചിട്ടി',
  'fieldGroup': 'ഗ്രൂപ്പ്',
  'groupHint': 'റിവർസൈഡ്',
  'eachSlotPays': 'ഓരോ സ്ലോട്ടും മാസം അടയ്ക്കുന്നത്',
  'lateFine': 'വൈകിയതിനുള്ള പിഴ',
  'fineNone': 'ഇല്ല',
  'slots': 'സ്ലോട്ടുകൾ',
  'fewerSlots': 'സ്ലോട്ട് കുറയ്ക്കുക',
  'moreSlots': 'സ്ലോട്ട് കൂട്ടുക',
  'potSummary': 'മാസം {pot} ചിട്ടിത്തുക, {n} മാസത്തേക്ക്',
  'potSummaryNone': 'ഓരോ മാസവും ഒരു സ്ലോട്ടിന് ചിട്ടി, {n} മാസത്തേക്ക്',
  'collectionDay': 'പിരിവ് ദിവസം',
  'everyMonthDay': 'എല്ലാ മാസവും {day}-ാം തീയതി',
  'lastDayToPay': 'അടയ്ക്കാനുള്ള അവസാന ദിവസം',
  'byMidnight': '{day}-ാം തീയതി, അർദ്ധരാത്രിക്കകം',
  'byMidnightNext': 'അടുത്ത മാസം {day}-ാം തീയതി, അർദ്ധരാത്രിക്കകം',
  'oneNamePerSlot': 'ഒരു സ്ലോട്ടിന് ഒരു പേര്',
  'numbersForReminders': 'ഓർമ്മപ്പെടുത്തലിനുള്ള നമ്പറുകൾ',
  'countOf': '{a} / {b}',
  'addNamesFirst': 'ആദ്യം സ്ലോട്ടുകളിൽ പേരുകൾ ചേർക്കുക.',
  'numbersNote': 'നമ്പറുകൾ WhatsApp ഓർമ്മപ്പെടുത്തലുകൾക്ക് മാത്രം. അംഗങ്ങളുടെ ലിങ്കിൽ അവ ഒരിക്കലും കാണിക്കില്ല.',
  'startTheChit': 'ചിട്ടി തുടങ്ങുക',
  'saveChanges': 'മാറ്റങ്ങൾ സേവ് ചെയ്യുക',
  'nameN': 'പേര് {n}',
  'remove': 'നീക്കം ചെയ്യുക',
  'splitSlot': 'ഈ സ്ലോട്ട് പങ്കിടുക',
  'addPerson': 'ഒരാളെ ചേർക്കുക',
  'somethingWrong': 'എന്തോ പിഴവ് സംഭവിച്ചു. വീണ്ടും ശ്രമിക്കുക.',
  'enterYourWa': 'നിങ്ങളുടെ WhatsApp നമ്പർ നൽകുക.',
  'enterCode': '6 അക്ക കോഡ് നൽകുക.',
  'enterEmailPassword': 'ഇമെയിലും പാസ്‌വേഡും നൽകുക.',
  'subPhoneCode': 'കോഡിനായി WhatsApp നോക്കുക.',
  'subEmailCode': 'കോഡിനായി ഇമെയിൽ നോക്കുക.',
  'subPhone': 'നിങ്ങളുടെ WhatsApp നമ്പർ ഉപയോഗിച്ച് സൈൻ ഇൻ ചെയ്യുക.',
  'subEmail': 'നിങ്ങളുടെ ഇമെയിൽ ഉപയോഗിച്ച് സൈൻ ഇൻ ചെയ്യുക.',
  'subStart': 'നിങ്ങളുടെ ചിട്ടി ഫോണിൽ നിന്ന് നടത്തൂ.',
  'privacy': 'സ്വകാര്യത',
  'terms': 'നിബന്ധനകൾ',
  'continueWa': 'WhatsApp വഴി തുടരുക',
  'useEmailInstead': 'പകരം ഇമെയിൽ ഉപയോഗിക്കുക',
  'phoneHint': 'ഫോൺ നമ്പർ',
  'sendCodeWa': 'WhatsApp-ൽ കോഡ് അയയ്ക്കുക',
  'codeSentWa': '{to} എന്ന നമ്പറിലേക്ക് WhatsApp-ൽ 6 അക്ക കോഡ് അയച്ചിട്ടുണ്ട്. 10 മിനിറ്റ് സാധുവാണ്.',
  'codeSentEmail': '{to} എന്ന വിലാസത്തിലേക്ക് 6 അക്ക കോഡ് അയച്ചിട്ടുണ്ട്. 10 മിനിറ്റ് സാധുവാണ്.',
  'signIn': 'സൈൻ ഇൻ',
  'sendAgainIn': '{n} സെക്കൻഡിനു ശേഷം വീണ്ടും അയയ്ക്കാം',
  'sendAgain': 'വീണ്ടും അയയ്ക്കുക',
  'anotherNumber': 'മറ്റൊരു നമ്പർ',
  'anotherEmail': 'മറ്റൊരു ഇമെയിൽ',
  'email': 'ഇമെയിൽ',
  'emailMeCode': 'ഇമെയിലിൽ കോഡ് അയയ്ക്കുക',
  'useWa': 'WhatsApp ഉപയോഗിക്കുക',
  'usePassword': 'പാസ്‌വേഡ് ഉപയോഗിക്കുക',
  'password': 'പാസ്‌വേഡ്',
  'emailCodeInstead': 'പകരം ഇമെയിലിൽ കോഡ് അയയ്ക്കുക',
  'countryCode': 'രാജ്യ കോഡ്',
  'signOutTitle': 'സൈൻ ഔട്ട് ചെയ്യണോ?',
  'signOutText': 'നിങ്ങളുടെ ചിട്ടികൾ സെർവറിൽ സുരക്ഷിതമായിരിക്കും. കാണാൻ വീണ്ടും സൈൻ ഇൻ ചെയ്യുക.',
  'signOut': 'സൈൻ ഔട്ട്',
  'deleteAccountTitle': 'നിങ്ങളുടെ അക്കൗണ്ട് ഡിലീറ്റ് ചെയ്യണോ?',
  'deleteAccountText': 'നിങ്ങളുടെ Kuree അക്കൗണ്ടും പേരും ഡിലീറ്റ് ആകും. നിങ്ങൾ ഉടമയായ ചിട്ടികൾ അടുത്ത അഡ്മിന് കൈമാറും. നിങ്ങൾ മാത്രം നടത്തുന്ന ചിട്ടികൾ അവയുടെ ചരിത്രവും അംഗങ്ങളുടെ ലിങ്കുകളും സഹിതം എന്നേക്കുമായി ഡിലീറ്റ് ആകും. ഇത് തിരിച്ചെടുക്കാനാവില്ല.',
  'deleteLoginToo': 'എന്റെ SkiFi ലോഗിനും ഡിലീറ്റ് ചെയ്യുക',
  'deleteLoginTooSub': 'നിങ്ങൾ സൈൻ ഇൻ ചെയ്യുന്ന നമ്പർ അല്ലെങ്കിൽ ഇമെയിൽ. അത് ഉപയോഗിക്കുന്ന മറ്റ് SkiFi ആപ്പുകൾക്കും അത് നഷ്ടമാകും.',
  'deleteAccount': 'അക്കൗണ്ട് ഡിലീറ്റ് ചെയ്യുക',
  'deleting': 'ഡിലീറ്റ് ചെയ്യുന്നു…',
  'noNameYet': 'ഇതുവരെ പേരില്ല',
  'edit': 'എഡിറ്റ്',
  'requestFeature': 'ഒരു ഫീച്ചർ ആവശ്യപ്പെടുക',
  'featureInbox': 'ഫീച്ചർ അഭ്യർത്ഥനകൾ',
  'contact': 'ബന്ധപ്പെടുക',
  'histPaid': 'മാസം {n}: {a} പേർ അടച്ചു, പിന്നീട് {b}',
  'histNoTaker': 'മാസം {n}-ന് അന്ന് ചിട്ടിക്കാരൻ ഇല്ലായിരുന്നു',
  'histWentTo': 'മാസം {n} {name}-ന് ആയിരുന്നു',
  'histFines': 'മാസം {n}: {count} പിഴകൾ',
  'histSettings': 'ക്രമീകരണങ്ങൾ വേറെ',
  'histPeople': 'ആളുകളോ സ്ലോട്ടുകളോ വേറെ',
  'histSmall': 'ചെറിയ മാറ്റങ്ങൾ',
  'histAndMore': 'കൂടാതെ മറ്റുള്ളവ',
  'restoreTitle': 'ഈ പതിപ്പ് തിരികെ കൊണ്ടുവരണോ?',
  'restoreText': '{name} {when} വിട്ടുപോയ നിലയിലേക്ക് ചിട്ടി മടങ്ങും. ഇപ്പോഴുള്ളതും ചരിത്രത്തിൽ സൂക്ഷിക്കും, അതിനാൽ ഇത് പഴയപടിയാക്കാം.',
  'putItBack': 'തിരികെ കൊണ്ടുവരിക',
  'historyEmpty': 'മുമ്പത്തെ പതിപ്പുകൾ ഇതുവരെയില്ല. ഓരോ സേവും ഒന്ന് ചേർക്കും.',
  'savedBy': 'സേവ് ചെയ്തത് {name}',
  'putBack': 'തിരികെ',
  'addAnAdmin': 'ഒരു അഡ്മിനെ ചേർക്കുക',
  'adminAdded': 'ചേർത്തു. സൈൻ ഇൻ ചെയ്യുമ്പോൾ അവർക്ക് ഈ ചിട്ടി കാണാം.',
  'leaveChitTitle': 'ഈ ചിട്ടി വിടണോ?',
  'removeAdminTitle': '{name}-നെ നീക്കണോ?',
  'leaveChitText': 'പിന്നെ നിങ്ങൾക്ക് ഇത് കാണാനോ മാറ്റാനോ കഴിയില്ല.',
  'removeAdminText': 'പിന്നെ അവർക്ക് ഈ ചിട്ടി കാണാനോ മാറ്റാനോ കഴിയില്ല.',
  'makeOwnerTitle': '{name}-നെ ഉടമയാക്കണോ?',
  'makeOwnerText': 'അവർക്ക് അഡ്മിൻമാരെ ചേർക്കാനും നീക്കാനും ചിട്ടി ഡിലീറ്റ് ചെയ്യാനും കഴിയും. നിങ്ങൾ അഡ്മിനായി തുടരും.',
  'makeOwner': 'ഉടമയാക്കുക',
  'ownsNow': 'ഇപ്പോൾ ചിട്ടിയുടെ ഉടമ {name}.',
  'addAdmin': 'അഡ്മിനെ ചേർക്കുക',
  'adminsExplain': 'അഡ്മിൻമാർ അടവുകൾ രേഖപ്പെടുത്തുന്നു, നറുക്കെടുപ്പ് നടത്തുന്നു, ഓർമ്മപ്പെടുത്തലുകൾ അയയ്ക്കുന്നു. ഉടമയ്ക്ക് അഡ്മിൻമാരെ ചേർക്കാനും നീക്കാനും കഴിയും.',
  'roleOwner': 'ഉടമ',
  'you': 'നിങ്ങൾ',
  'leaveChit': 'ഈ ചിട്ടി വിടുക',
  'removeAdmin': 'അഡ്മിനെ നീക്കുക',
  'enterTheirWa': 'അവരുടെ WhatsApp നമ്പർ നൽകുക.',
  'enterTheirEmail': 'അവരുടെ ഇമെയിൽ നൽകുക.',
  'theirName': 'അവരുടെ പേര്',
  'useEmail': 'ഇമെയിൽ ഉപയോഗിക്കുക',
  'adminSignInEmail': 'ചിട്ടി കാണാൻ അവർ ഈ ഇമെയിൽ ഉപയോഗിച്ച് Kuree-ൽ സൈൻ ഇൻ ചെയ്യണം.',
  'adminSignInNumber': 'ചിട്ടി കാണാൻ അവർ ഈ നമ്പർ ഉപയോഗിച്ച് Kuree-ൽ സൈൻ ഇൻ ചെയ്യണം.',
  'frTitle': 'ഒരു ഫീച്ചർ ആവശ്യപ്പെടുക',
  'frIntroTitle': 'എന്താണ് സഹായകമാകുക എന്ന് പറയൂ',
  'frIntroText': 'ഒരു ആശയം, തടസ്സമാകുന്ന എന്തെങ്കിലും, ഇല്ലാത്ത ഒരു ഫീച്ചർ. ഓരോ അഭ്യർത്ഥനയും ഞങ്ങൾ വായിക്കും.',
  'frFieldTitle': 'നിങ്ങളുടെ ആശയം ചുരുക്കത്തിൽ',
  'frFieldTitleHint': 'ഉദാഹരണം: തലേ ദിവസം ഒരു ഓർമ്മപ്പെടുത്തൽ',
  'frFieldDetails': 'കൂടുതൽ പറയൂ (ഐച്ഛികം)',
  'frFieldDetailsHint': 'നിങ്ങൾ ഇത് എങ്ങനെ ഉപയോഗിക്കും? ഇപ്പോൾ എന്താണ് സംഭവിക്കുന്നത്?',
  'frImportance': 'ഇത് എത്രത്തോളം സഹായിക്കും?',
  'frNice': 'ഉണ്ടെങ്കിൽ നല്ലത്',
  'frImportant': 'പ്രധാനം',
  'frMust': 'തീർച്ചയായും വേണം',
  'frSend': 'അഭ്യർത്ഥന അയയ്ക്കുക',
  'frNeedTitle': 'നിങ്ങളുടെ ആശയത്തിന് ഒരു ചെറിയ തലക്കെട്ട് നൽകുക.',
  'frThanksTitle': 'നന്ദി!',
  'frThanksText': 'നിങ്ങളുടെ അഭ്യർത്ഥന Kuree ടീമിന് കിട്ടി. താഴെ അത് പിന്തുടരാം.',
  'frSendAnother': 'മറ്റൊന്ന് അയയ്ക്കുക',
  'frYours': 'നിങ്ങളുടെ അഭ്യർത്ഥനകൾ',
  'frNoneYet': 'നിങ്ങളുടെ അഭ്യർത്ഥനകളും ടീമിന്റെ തീരുമാനവും ഇവിടെ കാണാം.',
  'frReply': 'Kuree ടീമിൽ നിന്ന്',
  'frInboxTitle': 'ഫീച്ചർ അഭ്യർത്ഥനകൾ',
  'frInboxEmpty': 'ഇവിടെ ഇതുവരെ അഭ്യർത്ഥനകളില്ല.',
  'frAll': 'എല്ലാം',
  'frStatusNew': 'പുതിയത്',
  'frStatusPlanned': 'പദ്ധതിയിൽ',
  'frStatusDone': 'ചെയ്തു',
  'frStatusDeclined': 'നിരസിച്ചു',
  'frChange': 'അഭ്യർത്ഥന പുതുക്കുക',
  'frNoteLabel': 'ചോദിച്ചയാൾക്കുള്ള കുറിപ്പ് (ഐച്ഛികം)',
  'frNoteHint': 'ഉദാഹരണം: അടുത്ത അപ്ഡേറ്റിൽ വരും',
  'frSaved': 'സേവ് ചെയ്തു.',
  'frFrom': 'അയച്ചത്',
  'frSignedOut': 'അക്കൗണ്ട് ഡിലീറ്റ് ചെയ്തു',
  'tabChits': 'ചിട്ടികൾ',
  'tabCollect': 'പിരിക്കാനുള്ളത്',
  'tabProfile': 'പ്രൊഫൈൽ',
  'collectIntro': 'ഈ മാസം ഇനിയും അടയ്ക്കാനുള്ളവർ, നിങ്ങളുടെ എല്ലാ ചിട്ടികളിലും.',
  'nothingToCollect': 'ഈ മാസം എല്ലാ ചിട്ടികളിലും എല്ലാവരും അടച്ചു.',
  'secPreferences': 'മുൻഗണനകൾ',
  'secHelp': 'സഹായം',
  'secLegal': 'നിയമപരം',
};

const Map<String, String> _ta = {
  'month1': 'ஜனவரி',
  'month2': 'பிப்ரவரி',
  'month3': 'மார்ச்',
  'month4': 'ஏப்ரல்',
  'month5': 'மே',
  'month6': 'ஜூன்',
  'month7': 'ஜூலை',
  'month8': 'ஆகஸ்ட்',
  'month9': 'செப்டம்பர்',
  'month10': 'அக்டோபர்',
  'month11': 'நவம்பர்',
  'month12': 'டிசம்பர்',
  'monthShort1': 'ஜன',
  'monthShort2': 'பிப்',
  'monthShort3': 'மார்',
  'monthShort4': 'ஏப்',
  'monthShort5': 'மே',
  'monthShort6': 'ஜூன்',
  'monthShort7': 'ஜூலை',
  'monthShort8': 'ஆக',
  'monthShort9': 'செப்',
  'monthShort10': 'அக்',
  'monthShort11': 'நவ',
  'monthShort12': 'டிச',
  'currencyINR': 'இந்திய ரூபாய்',
  'currencyAED': 'யுஏஇ திர்ஹாம்',
  'currencySAR': 'சவுதி ரியால்',
  'currencyQAR': 'கத்தார் ரியால்',
  'currencyKWD': 'குவைத் தினார்',
  'currencyOMR': 'ஓமன் ரியால்',
  'currencyBHD': 'பஹ்ரைன் தினார்',
  'currencyUSD': 'அமெரிக்க டாலர்',
  'currencyGBP': 'பிரிட்டிஷ் பவுண்டு',
  'currencyEUR': 'யூரோ',
  'currencySGD': 'சிங்கப்பூர் டாலர்',
  'currencyMYR': 'மலேசிய ரிங்கிட்',
  'currencyLKR': 'இலங்கை ரூபாய்',
  'country_in': 'இந்தியா',
  'country_ae': 'யுஏஇ',
  'country_sa': 'சவுதி அரேபியா',
  'country_qa': 'கத்தார்',
  'country_kw': 'குவைத்',
  'country_om': 'ஓமன்',
  'country_bh': 'பஹ்ரைன்',
  'country_us': 'அமெரிக்கா',
  'country_gb': 'ஐக்கிய இராச்சியம்',
  'country_au': 'ஆஸ்திரேலியா',
  'country_sg': 'சிங்கப்பூர்',
  'country_my': 'மலேசியா',
  'country_de': 'ஜெர்மனி',
  'lang_en': 'ஆங்கிலம்',
  'lang_ar': 'அரபு',
  'lang_ml': 'மலையாளம்',
  'lang_ta': 'தமிழ்',
  'lang_kn': 'கன்னடம்',
  'lang_hi': 'இந்தி',
  'account': 'கணக்கு',
  'askNameTitle': 'உங்களை என்ன பெயரில் அழைக்கலாம்?',
  'importDone': 'உங்கள் 5K சீட்டு வந்துவிட்டது.',
  'importTitle': 'உங்கள் 5K சீட்டைக் கொண்டு வாருங்கள்',
  'importButton': 'கொண்டு வா',
  'newChit': 'புதிய சீட்டு',
  'noChits': 'இன்னும் சீட்டுகள் இல்லை.',
  'startChit': 'ஒரு சீட்டைத் தொடங்குங்கள்',
  'yourChits': 'உங்கள் சீட்டுகள்',
  'roleAdmin': 'நிர்வாகி',
  'monthOfTotal': 'மாதம் {n} / {total}, {label}',
  'ofAmount': '{amount} இல்',
  'paidOfTotal': '{total} இல் {paid} பேர் செலுத்தினர்',
  'collectionNote': 'வசூல் {day} {month}, {note}',
  'takesPotName': 'சீட்டு எடுப்பவர்: {name}',
  'yourName': 'உங்கள் பெயர்',
  'save': 'சேமி',
  'cancel': 'ரத்து செய்',
  'close': 'மூடு',
  'yes': 'ஆம்',
  'tryAgain': 'மீண்டும் முயலவும்',
  'language': 'மொழி',
  'languagePhone': 'தொலைபேசியின் மொழி',
  'agoJustNow': 'இப்போது',
  'agoMinutes': '{n} நிமிடம் முன்பு',
  'agoToday': 'இன்று, {time}',
  'agoYesterday': 'நேற்று, {time}',
  'am': 'AM',
  'pm': 'PM',
  'andJoin': '{first} மற்றும் {last}',
  'slotN': 'ஸ்லாட் {n}',
  'someone': 'ஒருவர்',
  'shareHalf': '½ பங்கு',
  'shareThird': '⅓ பங்கு',
  'shareQuarter': '¼ பங்கு',
  'shareAmount': '{amount} பங்கு',
  'noteInDays': 'இன்னும் {n} நாட்களில்',
  'noteTomorrow': 'நாளை',
  'noteToday': 'இன்று',
  'noteDaysLeft': 'செலுத்த இன்னும் {n} நாட்கள்',
  'noteLastDayTomorrow': 'கடைசி நாள் நாளை',
  'notePayToday': 'இன்று நள்ளிரவுக்குள் செலுத்தவும்',
  'noteDeadlinePassed': 'கடைசி தேதி கடந்துவிட்டது',
  'errSessionEnded': 'உங்கள் உள்நுழைவு முடிந்துவிட்டது. மீண்டும் உள்நுழையவும்.',
  'errSignInAgain': 'மீண்டும் உள்நுழையவும்.',
  'errOffline': 'இணைப்பில் இல்லை.',
  'errTimeout': 'சர்வர் பதில் அளிக்க அதிக நேரம் எடுத்தது. இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.',
  'errNoConnection': 'இணைப்பு இல்லை. இணையத்தைச் சரிபார்த்து மீண்டும் முயலவும்.',
  'errServer': 'Kuree சர்வரில் ஒரு சிக்கல். ஒரு நிமிடம் கழித்து மீண்டும் முயலவும்.',
  'errStatus': 'ஏதோ தவறு நடந்தது ({status}).',
  'errNotOnWhatsApp': 'இந்த எண் WhatsApp இல் இல்லை.',
  'errCouldNotSend': 'குறியீட்டை அனுப்ப முடியவில்லை. ஒரு நிமிடம் கழித்து மீண்டும் முயலவும்.',
  'errTooMany': 'பல முயற்சிகள். ஒரு நிமிடம் காத்திருந்து மீண்டும் முயலவும்.',
  'errWrongCode': 'அந்தக் குறியீடு தவறு அல்லது காலாவதியானது. புதியதைக் கேளுங்கள்.',
  'errPasswordMismatch': 'அந்த மின்னஞ்சலும் கடவுச்சொல்லும் பொருந்தவில்லை.',
  'errPhoneCountry': 'நாட்டுக் குறியீட்டுடன் உங்கள் WhatsApp எண்ணை உள்ளிடவும்.',
  'errEmailLooksWrong': 'அந்த மின்னஞ்சல் சரியாகத் தெரியவில்லை.',
  'errSignInNotFinished': 'உள்நுழைவு முடியவில்லை. மீண்டும் முயலவும்.',
  'errFile': 'இப்போது கோப்பை உருவாக்க முடியவில்லை. ஒரு நிமிடம் கழித்து மீண்டும் முயலவும்.',
  'msgReminder': 'வணக்கம் {name}, ஒரு நினைவூட்டல்: உங்கள் {chit} மாதம் {n} ({label}) தவணை {amount}, {day} ஆம் தேதி நள்ளிரவுக்குள் செலுத்த வேண்டும்.',
  'msgReminderFrom': 'வணக்கம் {name}, {group} அனுப்பும் நினைவூட்டல்: உங்கள் {chit} மாதம் {n} ({label}) தவணை {amount}, {day} ஆம் தேதி நள்ளிரவுக்குள் செலுத்த வேண்டும்.',
  'msgFineAfter': ' அதன் பிறகு {fine} தாமதக் கட்டணம் உண்டு.',
  'msgThanks': ' நன்றி.',
  'msgPaidHead': '{month} : செலுத்தியவர்கள்',
  'msgDueHead': '{month} : இன்னும் செலுத்தாதவர்கள்',
  'msgDrawResult': '{chit}, மாதம் {n} ({label})\nபாட்டில் தேர்ந்தெடுத்தது: {slot}. {name}\n{pot} சீட்டுத் தொகை இவருக்கு.\nபாட்டிலில் {count} பெயர்கள் இருந்தன. குலுக்கல் {when}.',
  'savedMembersSee': 'சேமிக்கப்பட்டது. உறுப்பினர்கள் இப்போது பார்க்கலாம்.',
  'conflictTitle': 'வேறொருவர் இதைச் சேமித்துள்ளார்',
  'conflictText': 'சற்று முன் மற்றொரு நிர்வாகி இந்தச் சீட்டைச் சேமித்தார். அவரது மாற்றத்தைப் பார்க்க மீண்டும் ஏற்றவும், பிறகு உங்கள் மாற்றத்தை மீண்டும் செய்யவும்.',
  'reload': 'மீண்டும் ஏற்று',
  'nobodyYet': 'இன்னும் யாரும் இல்லை',
  'clearChoice': 'தேர்வை நீக்கு',
  'takesPotInMonth': 'மாதம் {n} இல் சீட்டு எடுப்பவர்',
  'allSlotsTaken': 'எல்லா ஸ்லாட்டுகளும் ஏற்கனவே சீட்டு எடுத்துவிட்டன.',
  'onlyOneLeft': '{name} மட்டுமே மீதம், அதனால் குலுக்க எதுவும் இல்லை. தேர்ந்தெடு என்பதைப் பயன்படுத்தவும்.',
  'savedMonthGoesTo': 'சேமிக்கப்பட்டது. மாதம் {n} {name} க்கு.',
  'drawDonePressSave': 'குலுக்கல் முடிந்தது. வெளியிட சேமி என்பதை அழுத்தவும்.',
  'numberAddedPressSave': 'எண் சேர்க்கப்பட்டது. வைத்திருக்க சேமி என்பதை அழுத்தவும்.',
  'slotsFromNames': 'கீழே பெயர்களைச் சேர்க்கவும். ஒவ்வொரு பெயரும் ஒரு ஸ்லாட், ஒவ்வொரு ஸ்லாட்டுக்கும் ஒரு மாதம்.',
  'fineChip': 'தாமதக் கட்டணம் {fine}',
  'fineEach': 'ஒவ்வொரு தாமதமான செலுத்துதலுக்கும் {fine}',
  'addLateFine': 'தாமதக் கட்டணம் சேர்க்கவும்',
  'fineSheetText': 'ஒவ்வொரு தாமதமான செலுத்துதலுக்கும் அந்த மாதச் சீட்டுத் தொகையில் சேரும். ஏற்கெனவே குறித்த கட்டணங்கள் அதே தொகையில் இருக்கும்.',
  'fineChangedPressSave': 'தாமதக் கட்டணம் இப்போது {fine}. வைத்திருக்க சேமி என்பதை அழுத்தவும்.',
  'fineOffPressSave': 'இனி தாமதக் கட்டணம் இல்லை. வைத்திருக்க சேமி என்பதை அழுத்தவும்.',
  'newLinkTitle': 'புதிய இணைப்பை உருவாக்கவா?',
  'newLinkText': 'பழைய இணைப்பு உடனே வேலை செய்யாது. புதியதைக் குழுவில் பகிருங்கள்.',
  'newLinkYes': 'புதிய இணைப்பை உருவாக்கு',
  'makingSheet': 'விரிதாளை உருவாக்குகிறது…',
  'saveFirstTitle': 'முதலில் சேமிக்கவா?',
  'saveFirstText': 'சீட்டைத் திருத்தும் முன் இந்த மாத மாற்றங்களைச் சேமிக்கவும்.',
  'deleteChitTitle': '{name} ஐ நீக்கவா?',
  'deleteChitText': 'சீட்டு, அதன் வரலாறு, உறுப்பினர் இணைப்பு அனைத்தும் நிரந்தரமாக நீக்கப்படும். இதைத் திரும்பப் பெற முடியாது.',
  'delete': 'நீக்கு',
  'membersLink': 'உறுப்பினர் இணைப்பு',
  'membersLinkSub': 'குழுவில் பகிருங்கள்',
  'drawRest': 'மீதியைக் குலுக்கு',
  'drawRestSub': 'இன்னும் திறந்திருக்கும் எல்லா மாதங்களையும் கலக்கு',
  'spreadsheet': 'விரிதாள்',
  'spreadsheetSub': 'ஒவ்வொரு மாதமும், ஒவ்வொரு உறுப்பினரும்',
  'history': 'வரலாறு',
  'historySub': 'முந்தைய எல்லாப் பதிப்புகளும்',
  'admins': 'நிர்வாகிகள்',
  'adminsSub': 'இந்தச் சீட்டை நடத்துபவர்கள்',
  'editChit': 'சீட்டைத் திருத்து',
  'editChitSub': 'பெயர், தொகைகள், நாணயம், தேதிகள், ஸ்லாட்டுகள், நபர்கள்',
  'deleteChit': 'சீட்டை நீக்கு',
  'leaveTitle': 'சேமிக்காமல் வெளியேறவா?',
  'leaveText': 'இந்த மாதத்துக்கான உங்கள் மாற்றங்கள் இன்னும் சேமிக்கப்படவில்லை.',
  'leave': 'வெளியேறு',
  'more': 'மேலும்',
  'saveChangesFirst': 'முதலில் உங்கள் மாற்றங்களைச் சேமிக்கவும்.',
  'historyKept': 'ஒவ்வொரு சேமிப்பும் வரலாற்றில் வைக்கப்படும், எதுவும் இழக்கப்படாது.',
  'lastSavedBy': 'கடைசியாகச் சேமித்தவர் {name}, {when}',
  'notSavedYet': 'இன்னும் சேமிக்கப்படவில்லை',
  'undo': 'செயல்தவிர்',
  'prevMonth': 'முந்தைய மாதம்',
  'nextMonth': 'அடுத்த மாதம்',
  'prevYear': 'முந்தைய ஆண்டு',
  'nextYear': 'அடுத்த ஆண்டு',
  'monthNLabel': 'மாதம் {n}, {label}',
  'collectedOf': '{pot} இல் வசூலானது',
  'collectedOfFines': '{pot} இல் வசூலானது, கூடுதலாக {fines} அபராதம்',
  'toGo': 'இன்னும் {n} பேர்',
  'everyonePaid': 'எல்லோரும் செலுத்தினர்',
  'heroCollection': 'வசூல் {day} {month}, {payDay} {payMonth} க்குள் செலுத்தவும்: {note}',
  'month': 'மாதம்',
  'settled': 'முடிந்தது',
  'inProgress': 'நடைபெறுகிறது',
  'inProgressTakes': 'நடைபெறுகிறது, சீட்டு {name} க்கு',
  'upcoming': 'வரவிருக்கிறது',
  'upcomingTakes': 'வரவிருக்கிறது, சீட்டு {name} க்கு',
  'winnerAmountFine': '{total} (சீட்டுத் தொகையும் {fine} அபராதமும்)',
  'pickedFromBottle': '{amount}, பாட்டிலில் இருந்து எடுக்கப்பட்டது',
  'takesPotThisMonth': 'இந்த மாதம் சீட்டு எடுப்பவர்',
  'notDecided': 'இன்னும் முடிவாகவில்லை',
  'bottleDraw': 'பாட்டில் குலுக்கல்',
  'choose': 'தேர்ந்தெடு',
  'change': 'மாற்று',
  'allPaid': 'எல்லோரும் செலுத்தினர்',
  'reminders': 'நினைவூட்டல்கள்',
  'everyonePaidFor': 'மாதம் {n} க்கு எல்லோரும் செலுத்தினர்',
  'showList': 'காட்டு',
  'hideList': 'மறை',
  'filterAll': 'அனைவரும் {n}',
  'filterDue': 'செலுத்த வேண்டியவர் {n}',
  'filterPaid': 'செலுத்தியவர் {n}',
  'tickHelp': 'யாராவது செலுத்தும்போது டிக்கைத் தட்டவும். கடைசி தேதிக்குப் பிறகு செலுத்தினால் தாமதம் என்பதைத் தட்டவும்.',
  'everyonePaidMonth': 'மாதம் {n} க்கு எல்லோரும் செலுத்திவிட்டனர்.',
  'nobodyPaidMonth': 'மாதம் {n} க்கு இன்னும் யாரும் செலுத்தவில்லை.',
  'statusPaid': 'செலுத்தியது {amount}',
  'statusPending': 'நிலுவை {amount}',
  'statusLateFine': '{status}, தாமதக் கட்டணம் {fine}',
  'monthN': 'மாதம் {n}',
  'semPaid': 'செலுத்தியது: {name}',
  'semLate': 'தாமதக் கட்டணம், {name}',
  'lateButton': 'தாமதம்',
  'couldNotOpen': 'அதைத் திறக்க முடியவில்லை. WhatsApp நிறுவப்பட்டுள்ளதா?',
  'copied': 'நகலெடுக்கப்பட்டது',
  'drawTitle': 'மாதம் {n} குலுக்கல்',
  'drawSubtitle': '{label}, சீட்டுத் தொகை {pot}',
  'savedToPhotos': 'உங்கள் படங்களில் சேமிக்கப்பட்டது.',
  'videoFailed': 'இந்தத் தொலைபேசியில் வீடியோவை உருவாக்க முடியவில்லை.',
  'drawShareTitle': '{title}, மாதம் {n} குலுக்கல்',
  'stopDrawTitle': 'குலுக்கலை நிறுத்தவா?',
  'nothingSaved': 'எதுவும் சேமிக்கப்படாது.',
  'stop': 'நிறுத்து',
  'closeUnsavedTitle': 'சேமிக்காமல் மூடவா?',
  'winnerNotSaved': 'சீட்டு எடுப்பவர் இன்னும் சேமிக்கப்படவில்லை.',
  'slipsGoIn': '{n} சீட்டுகள் பாட்டிலுக்குள், இன்னும் சீட்டுக்குக் காத்திருக்கும் ஒவ்வொரு ஸ்லாட்டுக்கும் ஒன்று.',
  'recordHint': 'இந்தத் திரைக்கு மேலே இன்னொரு தொலைபேசியைப் பிடித்து பதிவு செய்யத் தொடங்குங்கள், பிறகு குலுக்கலைத் தொடங்கு என்பதை அழுத்துங்கள். 3 இல் இருந்து எண்ணும்.',
  'musicSound': 'இசையும் ஒலிகளும்',
  'gettingReady': 'தயாராகிறது',
  'startDraw': 'குலுக்கலைத் தொடங்கு',
  'takesPotFor': 'மாதம் {n}, {label}: சீட்டு இவருக்கு.',
  'saved': 'சேமிக்கப்பட்டது',
  'saveAsWinner': 'மாதம் {n} சீட்டு எடுப்பவராகச் சேமி',
  'makingVideo': 'வீடியோ உருவாகிறது {pct}%',
  'shareVideo': 'வீடியோவைப் பகிர்',
  'saveVideo': 'வீடியோவைச் சேமி',
  'sendResultWa': 'முடிவை WhatsApp இல் அனுப்பு',
  'drawGetReady': 'தயாராகுங்கள்',
  'drawStartsSoon': 'குலுக்கல் சற்று நேரத்தில் தொடங்கும்',
  'drawWriting': 'ஒவ்வொரு பெயரையும் எழுதுகிறது',
  'drawWritingSub': 'சீட்டுக்குக் காத்திருக்கும் ஒவ்வொரு ஸ்லாட்டுக்கும் ஒரு சீட்டு',
  'drawInto': 'பாட்டிலுக்குள்',
  'drawClosing': 'பாட்டிலை மூடுகிறது',
  'drawShaking': 'குலுக்குகிறது',
  'drawShakingSub': 'ஒவ்வொரு சீட்டுக்கும் ஒரே வாய்ப்பு',
  'drawPicking': 'ஒன்றை எடுக்கிறது',
  'drawFooterDrawn': 'பாட்டிலில் {n} பெயர்கள். குலுக்கல் {when}',
  'drawFooterNow': 'பாட்டிலில் {n} பெயர்கள். {when}',
  'everyMonthTaken': 'அடுத்த மாதம் முதல் எல்லா மாதங்களுக்கும் ஏற்கனவே சீட்டு எடுப்பவர் உள்ளனர்.',
  'drawRestIntro': 'இன்னும் சீட்டு எடுக்காத {slots} ஸ்லாட்டுகள், {from} முதல் {months} மாதங்களில். ஒவ்வொரு ஸ்லாட்டும் ஒரு குலுக்கல்.',
  'drawRestIntroOne': 'இன்னும் சீட்டு எடுக்காத {slots} ஸ்லாட்டுகள், {from} முதல் 1 மாதத்தில். ஒவ்வொரு ஸ்லாட்டும் ஒரு குலுக்கல்.',
  'noSlotLeft': 'ஸ்லாட் மீதமில்லை',
  'notPlaced': 'சேர்க்கப்படவில்லை (மாதம் மீதமில்லை): {list}',
  'useThisOrder': 'இந்த வரிசையைப் பயன்படுத்து',
  'useOrderTitle': 'இந்த வரிசையைப் பயன்படுத்தவா?',
  'useOrderText': 'இது {n} மாதங்களுக்கு சீட்டு எடுப்பவர்களை அமைக்கும். சேமிக்கும் முன் எந்த மாதத்தையும் கைமுறையாக மாற்றலாம்.',
  'useIt': 'பயன்படுத்து',
  'shuffleAgain': 'மீண்டும் கலக்கு',
  'remindersTitle': 'நினைவூட்டல்கள், மாதம் {n}',
  'shareListInGroup': 'பட்டியலைக் குழுவில் பகிர்',
  'nobodyToRemind': 'எல்லோரும் செலுத்திவிட்டனர், நினைவூட்ட யாரும் இல்லை.',
  'remindEach': 'அல்லது ஒவ்வொருவருக்கும் செய்தி அனுப்புங்கள். {rest}',
  'everyoneHasNumber': 'இங்கே எல்லோருக்கும் எண் உள்ளது.',
  'noNumberOne': '1 நபருக்கு இன்னும் எண் இல்லை.',
  'noNumberMany': '{n} பேருக்கு இன்னும் எண் இல்லை.',
  'noNumberYet': 'இன்னும் எண் இல்லை',
  'dueMonth': '{amount} நிலுவை, மாதம் {n}',
  'addNumber': 'எண்ணைச் சேர்',
  'sent': 'அனுப்பப்பட்டது',
  'remind': 'நினைவூட்டு',
  'couldNotOpenWa': 'WhatsApp ஐத் திறக்க முடியவில்லை.',
  'numberTitle': '{name} இன் எண்',
  'enterWaNumber': 'WhatsApp எண்ணை உள்ளிடவும்.',
  'waNumberHint': 'WhatsApp எண்',
  'numberUse': 'நினைவூட்டல்களுக்கு மட்டும். உறுப்பினர்கள் இதைப் பார்க்க மாட்டார்கள்.',
  'saveNumber': 'எண்ணைச் சேமி',
  'linkExplain': 'உறுப்பினர்கள் இதை எந்த உலாவியிலும் திறக்கலாம். யார் செலுத்தினர், அபராதங்கள், யார் சீட்டு எடுத்தார், அடுத்தது என்ன என்பதைப் பார்க்கலாம். செயலியோ உள்நுழைவோ தேவையில்லை, தொலைபேசி எண்கள் தெரியாது.',
  'copy': 'நகலெடு',
  'linkCopied': 'இணைப்பு நகலெடுக்கப்பட்டது',
  'whatsapp': 'WhatsApp',
  'open': 'திற',
  'share': 'பகிர்',
  'errNeedName': 'சீட்டுக்கு ஒரு பெயர் கொடுங்கள், எ.கா. 5K சீட்டு.',
  'errNeedShare': 'ஒவ்வொரு ஸ்லாட்டும் மாதம் எவ்வளவு செலுத்தும் என்பதை உள்ளிடவும்.',
  'errSlotName': 'ஸ்லாட் {n} க்கு ஒரு பெயர் தேவை.',
  'errPartsSum': 'ஸ்லாட் {n}: பங்குகளின் கூட்டு {total}, ஆனால் ஒரு ஸ்லாட் செலுத்துவது {share}.',
  'errPartAmount': 'ஸ்லாட் {n}: ஒவ்வொருவரும் செலுத்தும் தொகையை உள்ளிடவும்.',
  'errFewerSlots': 'மாதம் {n} இல் ஏற்கனவே கட்டணங்கள் அல்லது சீட்டு எடுத்தவர் உள்ளனர், எனவே சீட்டுக்கு {n} ஐ விடக் குறைவான ஸ்லாட்டுகள் இருக்க முடியாது.',
  'errTakerSlot': 'ஸ்லாட் {slot} மாதம் {n} இல் சீட்டு எடுத்தது, எனவே சீட்டுக்குக் குறைந்தது {slot} ஸ்லாட்டுகள் தேவை.',
  'errConflictEditor': 'சற்று முன் மற்றொரு நிர்வாகி இந்தச் சீட்டைச் சேமித்தார். பின்னால் சென்று மீண்டும் ஏற்றி, உங்கள் மாற்றங்களை மீண்டும் செய்யவும்.',
  'firstMonth': 'முதல் மாதம்',
  'shorterMonths': 'குறைந்த நாட்கள் உள்ள மாதங்களில் கடைசி நாள்',
  'currency': 'நாணயம்',
  'sectionChit': 'சீட்டு',
  'sectionMoney': 'பணம்',
  'sectionDates': 'தேதிகள்',
  'fieldName': 'பெயர்',
  'nameHint': '5K சீட்டு',
  'fieldGroup': 'குழு',
  'groupHint': 'ரிவர்சைடு',
  'eachSlotPays': 'ஒவ்வொரு ஸ்லாட்டும் மாதம் செலுத்துவது',
  'lateFine': 'தாமதக் கட்டணம்',
  'fineNone': 'இல்லை',
  'slots': 'ஸ்லாட்டுகள்',
  'fewerSlots': 'ஸ்லாட்டைக் குறை',
  'moreSlots': 'ஸ்லாட்டைக் கூட்டு',
  'potSummary': 'மாதம் {pot} சீட்டுத் தொகை, {n} மாதங்களுக்கு',
  'potSummaryNone': 'ஒவ்வொரு மாதமும் ஒரு ஸ்லாட் சீட்டு எடுக்கும், {n} மாதங்களுக்கு',
  'collectionDay': 'வசூல் நாள்',
  'everyMonthDay': 'ஒவ்வொரு மாதமும் {day} ஆம் தேதி',
  'lastDayToPay': 'செலுத்த கடைசி நாள்',
  'byMidnight': '{day} ஆம் தேதி, நள்ளிரவுக்குள்',
  'byMidnightNext': 'அடுத்த மாதம் {day} ஆம் தேதி, நள்ளிரவுக்குள்',
  'oneNamePerSlot': 'ஒரு ஸ்லாட்டுக்கு ஒரு பெயர்',
  'numbersForReminders': 'நினைவூட்டலுக்கான எண்கள்',
  'countOf': '{a} / {b}',
  'addNamesFirst': 'முதலில் ஸ்லாட்டுகளில் பெயர்களைச் சேர்க்கவும்.',
  'numbersNote': 'எண்கள் WhatsApp நினைவூட்டல்களுக்கு மட்டும். உறுப்பினர் இணைப்பில் அவை ஒருபோதும் தெரியாது.',
  'startTheChit': 'சீட்டைத் தொடங்கு',
  'saveChanges': 'மாற்றங்களைச் சேமி',
  'nameN': 'பெயர் {n}',
  'remove': 'நீக்கு',
  'splitSlot': 'இந்த ஸ்லாட்டைப் பிரி',
  'addPerson': 'ஒருவரைச் சேர்',
  'somethingWrong': 'ஏதோ தவறு நடந்தது. மீண்டும் முயலவும்.',
  'enterYourWa': 'உங்கள் WhatsApp எண்ணை உள்ளிடவும்.',
  'enterCode': '6 இலக்கக் குறியீட்டை உள்ளிடவும்.',
  'enterEmailPassword': 'மின்னஞ்சலையும் கடவுச்சொல்லையும் உள்ளிடவும்.',
  'subPhoneCode': 'குறியீட்டுக்கு WhatsApp ஐப் பாருங்கள்.',
  'subEmailCode': 'குறியீட்டுக்கு உங்கள் மின்னஞ்சலைப் பாருங்கள்.',
  'subPhone': 'உங்கள் WhatsApp எண்ணுடன் உள்நுழையுங்கள்.',
  'subEmail': 'உங்கள் மின்னஞ்சலுடன் உள்நுழையுங்கள்.',
  'subStart': 'உங்கள் சீட்டை உங்கள் தொலைபேசியிலிருந்து நடத்துங்கள்.',
  'privacy': 'தனியுரிமை',
  'terms': 'விதிமுறைகள்',
  'continueWa': 'WhatsApp உடன் தொடரவும்',
  'useEmailInstead': 'பதிலாக மின்னஞ்சலைப் பயன்படுத்து',
  'phoneHint': 'தொலைபேசி எண்',
  'sendCodeWa': 'WhatsApp இல் குறியீட்டை அனுப்பு',
  'codeSentWa': '{to} க்கு WhatsApp இல் 6 இலக்கக் குறியீட்டை அனுப்பியுள்ளோம். அது 10 நிமிடங்கள் செல்லும்.',
  'codeSentEmail': '{to} க்கு 6 இலக்கக் குறியீட்டை அனுப்பியுள்ளோம். அது 10 நிமிடங்கள் செல்லும்.',
  'signIn': 'உள்நுழை',
  'sendAgainIn': '{n} வினாடிகளில் மீண்டும் அனுப்பலாம்',
  'sendAgain': 'மீண்டும் அனுப்பு',
  'anotherNumber': 'வேறு எண்',
  'anotherEmail': 'வேறு மின்னஞ்சல்',
  'email': 'மின்னஞ்சல்',
  'emailMeCode': 'மின்னஞ்சலில் குறியீடு அனுப்பு',
  'useWa': 'WhatsApp ஐப் பயன்படுத்து',
  'usePassword': 'கடவுச்சொல்லைப் பயன்படுத்து',
  'password': 'கடவுச்சொல்',
  'emailCodeInstead': 'பதிலாக மின்னஞ்சலில் குறியீடு அனுப்பு',
  'countryCode': 'நாட்டுக் குறியீடு',
  'signOutTitle': 'வெளியேறவா?',
  'signOutText': 'உங்கள் சீட்டுகள் சர்வரில் பாதுகாப்பாக இருக்கும். அவற்றைப் பார்க்க மீண்டும் உள்நுழையுங்கள்.',
  'signOut': 'வெளியேறு',
  'deleteAccountTitle': 'உங்கள் கணக்கை நீக்கவா?',
  'deleteAccountText': 'உங்கள் Kuree கணக்கும் பெயரும் நீக்கப்படும். நீங்கள் உரிமையாளராக உள்ள சீட்டுகள் அடுத்த நிர்வாகிக்குச் செல்லும். நீங்கள் மட்டும் நடத்தும் சீட்டுகள் அவற்றின் வரலாறு, உறுப்பினர் இணைப்புகளுடன் நிரந்தரமாக நீக்கப்படும். இதைத் திரும்பப் பெற முடியாது.',
  'deleteLoginToo': 'என் SkiFi உள்நுழைவையும் நீக்கு',
  'deleteLoginTooSub': 'நீங்கள் உள்நுழையும் எண் அல்லது மின்னஞ்சல். அதைப் பயன்படுத்தும் மற்ற SkiFi செயலிகளும் அதை இழக்கும்.',
  'deleteAccount': 'கணக்கை நீக்கு',
  'deleting': 'நீக்குகிறது…',
  'noNameYet': 'இன்னும் பெயர் இல்லை',
  'edit': 'திருத்து',
  'requestFeature': 'ஒரு வசதியைக் கேளுங்கள்',
  'featureInbox': 'வசதிக் கோரிக்கைகள்',
  'contact': 'தொடர்பு',
  'histPaid': 'மாதம் {n}: {a} பேர் செலுத்தினர், பின்னர் {b}',
  'histNoTaker': 'மாதம் {n} க்கு அப்போது சீட்டு எடுப்பவர் இல்லை',
  'histWentTo': 'மாதம் {n} {name} க்குச் சென்றது',
  'histFines': 'மாதம் {n}: {count} தாமதக் கட்டணங்கள்',
  'histSettings': 'வேறு அமைப்புகள்',
  'histPeople': 'வேறு நபர்கள் அல்லது ஸ்லாட்டுகள்',
  'histSmall': 'சிறிய மாற்றங்கள்',
  'histAndMore': 'மேலும் பல',
  'restoreTitle': 'இந்தப் பதிப்பைத் திரும்பக் கொண்டு வரவா?',
  'restoreText': '{name} {when} விட்டுச் சென்ற நிலைக்குச் சீட்டு திரும்பும். இப்போது உள்ளதும் வரலாற்றில் வைக்கப்படும், எனவே இதைச் செயல்தவிர்க்கலாம்.',
  'putItBack': 'திரும்பக் கொண்டு வா',
  'historyEmpty': 'இன்னும் முந்தைய பதிப்புகள் இல்லை. ஒவ்வொரு சேமிப்பும் ஒன்றைச் சேர்க்கும்.',
  'savedBy': 'சேமித்தவர் {name}',
  'putBack': 'திரும்ப',
  'addAnAdmin': 'ஒரு நிர்வாகியைச் சேர்',
  'adminAdded': 'சேர்க்கப்பட்டது. உள்நுழையும்போது அவர்கள் இந்தச் சீட்டைப் பார்ப்பார்கள்.',
  'leaveChitTitle': 'இந்தச் சீட்டிலிருந்து விலகவா?',
  'removeAdminTitle': '{name} ஐ நீக்கவா?',
  'leaveChitText': 'பிறகு நீங்கள் இதைப் பார்க்கவோ மாற்றவோ முடியாது.',
  'removeAdminText': 'பிறகு அவர்கள் இந்தச் சீட்டைப் பார்க்கவோ மாற்றவோ முடியாது.',
  'makeOwnerTitle': '{name} ஐ உரிமையாளர் ஆக்கவா?',
  'makeOwnerText': 'அவர்கள் நிர்வாகிகளைச் சேர்க்கவும் நீக்கவும், சீட்டை நீக்கவும் முடியும். நீங்கள் நிர்வாகியாகத் தொடர்வீர்கள்.',
  'makeOwner': 'உரிமையாளர் ஆக்கு',
  'ownsNow': 'இப்போது சீட்டின் உரிமையாளர் {name}.',
  'addAdmin': 'நிர்வாகியைச் சேர்',
  'adminsExplain': 'நிர்வாகிகள் கட்டணங்களைக் குறிக்கிறார்கள், குலுக்கலை நடத்துகிறார்கள், நினைவூட்டல்களை அனுப்புகிறார்கள். உரிமையாளர் நிர்வாகிகளைச் சேர்க்கவும் நீக்கவும் செய்வார்.',
  'roleOwner': 'உரிமையாளர்',
  'you': 'நீங்கள்',
  'leaveChit': 'இந்தச் சீட்டிலிருந்து விலகு',
  'removeAdmin': 'நிர்வாகியை நீக்கு',
  'enterTheirWa': 'அவர்களின் WhatsApp எண்ணை உள்ளிடவும்.',
  'enterTheirEmail': 'அவர்களின் மின்னஞ்சலை உள்ளிடவும்.',
  'theirName': 'அவர்களின் பெயர்',
  'useEmail': 'மின்னஞ்சலைப் பயன்படுத்து',
  'adminSignInEmail': 'சீட்டைப் பார்க்க அவர்கள் இந்த மின்னஞ்சலுடன் Kuree இல் உள்நுழைய வேண்டும்.',
  'adminSignInNumber': 'சீட்டைப் பார்க்க அவர்கள் இந்த எண்ணுடன் Kuree இல் உள்நுழைய வேண்டும்.',
  'frTitle': 'ஒரு வசதியைக் கேளுங்கள்',
  'frIntroTitle': 'எது உதவும் என்று சொல்லுங்கள்',
  'frIntroText': 'ஒரு யோசனை, தடையாக இருக்கும் ஒன்று, இல்லாத ஒரு வசதி. ஒவ்வொரு கோரிக்கையையும் படிக்கிறோம்.',
  'frFieldTitle': 'உங்கள் யோசனை சில வார்த்தைகளில்',
  'frFieldTitleHint': 'எ.கா.: முந்தைய நாள் ஒரு நினைவூட்டல்',
  'frFieldDetails': 'மேலும் சொல்லுங்கள் (விருப்பம்)',
  'frFieldDetailsHint': 'இதை எப்படிப் பயன்படுத்துவீர்கள்? இன்று என்ன நடக்கிறது?',
  'frImportance': 'இது எவ்வளவு உதவும்?',
  'frNice': 'இருந்தால் நல்லது',
  'frImportant': 'முக்கியம்',
  'frMust': 'கட்டாயம் வேண்டும்',
  'frSend': 'கோரிக்கையை அனுப்பு',
  'frNeedTitle': 'உங்கள் யோசனைக்கு ஒரு சிறிய தலைப்பு கொடுங்கள்.',
  'frThanksTitle': 'நன்றி!',
  'frThanksText': 'உங்கள் கோரிக்கை Kuree குழுவைச் சென்றடைந்தது. கீழே அதைப் பின்தொடரலாம்.',
  'frSendAnother': 'இன்னொன்று அனுப்பு',
  'frYours': 'உங்கள் கோரிக்கைகள்',
  'frNoneYet': 'உங்கள் கோரிக்கைகளும் குழுவின் முடிவும் இங்கே தெரியும்.',
  'frReply': 'Kuree குழுவிடமிருந்து',
  'frInboxTitle': 'வசதிக் கோரிக்கைகள்',
  'frInboxEmpty': 'இங்கே இன்னும் கோரிக்கைகள் இல்லை.',
  'frAll': 'அனைத்தும்',
  'frStatusNew': 'புதியது',
  'frStatusPlanned': 'திட்டத்தில்',
  'frStatusDone': 'முடிந்தது',
  'frStatusDeclined': 'நிராகரிக்கப்பட்டது',
  'frChange': 'கோரிக்கையைப் புதுப்பி',
  'frNoteLabel': 'கேட்டவருக்கான குறிப்பு (விருப்பம்)',
  'frNoteHint': 'எ.கா.: அடுத்த புதுப்பிப்பில் வரும்',
  'frSaved': 'சேமிக்கப்பட்டது.',
  'frFrom': 'அனுப்பியவர்',
  'frSignedOut': 'கணக்கு நீக்கப்பட்டது',
  'tabChits': 'சீட்டுகள்',
  'tabCollect': 'வசூலிக்க',
  'tabProfile': 'சுயவிவரம்',
  'collectIntro': 'இந்த மாதம் இன்னும் செலுத்த வேண்டியவர்கள், உங்கள் எல்லா சீட்டுகளிலும்.',
  'nothingToCollect': 'இந்த மாதம் எல்லா சீட்டுகளிலும் எல்லோரும் செலுத்திவிட்டனர்.',
  'secPreferences': 'விருப்பங்கள்',
  'secHelp': 'உதவி',
  'secLegal': 'சட்டம்',
};

const Map<String, String> _kn = {
  'month1': 'ಜನವರಿ',
  'month2': 'ಫೆಬ್ರವರಿ',
  'month3': 'ಮಾರ್ಚ್',
  'month4': 'ಏಪ್ರಿಲ್',
  'month5': 'ಮೇ',
  'month6': 'ಜೂನ್',
  'month7': 'ಜುಲೈ',
  'month8': 'ಆಗಸ್ಟ್',
  'month9': 'ಸೆಪ್ಟೆಂಬರ್',
  'month10': 'ಅಕ್ಟೋಬರ್',
  'month11': 'ನವೆಂಬರ್',
  'month12': 'ಡಿಸೆಂಬರ್',
  'monthShort1': 'ಜನ',
  'monthShort2': 'ಫೆಬ್ರ',
  'monthShort3': 'ಮಾರ್ಚ್',
  'monthShort4': 'ಏಪ್ರಿ',
  'monthShort5': 'ಮೇ',
  'monthShort6': 'ಜೂನ್',
  'monthShort7': 'ಜುಲೈ',
  'monthShort8': 'ಆಗ',
  'monthShort9': 'ಸೆಪ್ಟೆಂ',
  'monthShort10': 'ಅಕ್ಟೋ',
  'monthShort11': 'ನವೆಂ',
  'monthShort12': 'ಡಿಸೆಂ',
  'currencyINR': 'ಭಾರತೀಯ ರೂಪಾಯಿ',
  'currencyAED': 'ಯುಎಇ ದಿರ್ಹಾಮ್',
  'currencySAR': 'ಸೌದಿ ರಿಯಾಲ್',
  'currencyQAR': 'ಕತಾರ್ ರಿಯಾಲ್',
  'currencyKWD': 'ಕುವೈತ್ ದಿನಾರ್',
  'currencyOMR': 'ಒಮಾನ್ ರಿಯಾಲ್',
  'currencyBHD': 'ಬಹ್ರೇನ್ ದಿನಾರ್',
  'currencyUSD': 'ಅಮೆರಿಕನ್ ಡಾಲರ್',
  'currencyGBP': 'ಬ್ರಿಟಿಷ್ ಪೌಂಡ್',
  'currencyEUR': 'ಯೂರೋ',
  'currencySGD': 'ಸಿಂಗಾಪುರ ಡಾಲರ್',
  'currencyMYR': 'ಮಲೇಷ್ಯನ್ ರಿಂಗಿಟ್',
  'currencyLKR': 'ಶ್ರೀಲಂಕಾ ರೂಪಾಯಿ',
  'country_in': 'ಭಾರತ',
  'country_ae': 'ಯುಎಇ',
  'country_sa': 'ಸೌದಿ ಅರೇಬಿಯಾ',
  'country_qa': 'ಕತಾರ್',
  'country_kw': 'ಕುವೈತ್',
  'country_om': 'ಒಮಾನ್',
  'country_bh': 'ಬಹ್ರೇನ್',
  'country_us': 'ಅಮೆರಿಕ',
  'country_gb': 'ಯುನೈಟೆಡ್ ಕಿಂಗ್‌ಡಮ್',
  'country_au': 'ಆಸ್ಟ್ರೇಲಿಯಾ',
  'country_sg': 'ಸಿಂಗಾಪುರ',
  'country_my': 'ಮಲೇಷ್ಯಾ',
  'country_de': 'ಜರ್ಮನಿ',
  'lang_en': 'ಇಂಗ್ಲಿಷ್',
  'lang_ar': 'ಅರೇಬಿಕ್',
  'lang_ml': 'ಮಲಯಾಳಂ',
  'lang_ta': 'ತಮಿಳು',
  'lang_kn': 'ಕನ್ನಡ',
  'lang_hi': 'ಹಿಂದಿ',
  'account': 'ಖಾತೆ',
  'askNameTitle': 'ನಿಮ್ಮನ್ನು ಯಾವ ಹೆಸರಿನಿಂದ ಕರೆಯಲಿ?',
  'importDone': 'ನಿಮ್ಮ 5K ಚೀಟಿ ಬಂದಿದೆ.',
  'importTitle': 'ನಿಮ್ಮ 5K ಚೀಟಿಯನ್ನು ತನ್ನಿ',
  'importButton': 'ತನ್ನಿ',
  'newChit': 'ಹೊಸ ಚೀಟಿ',
  'noChits': 'ಇನ್ನೂ ಯಾವುದೇ ಚೀಟಿ ಇಲ್ಲ.',
  'startChit': 'ಒಂದು ಚೀಟಿ ಆರಂಭಿಸಿ',
  'yourChits': 'ನಿಮ್ಮ ಚೀಟಿಗಳು',
  'roleAdmin': 'ನಿರ್ವಾಹಕ',
  'monthOfTotal': 'ತಿಂಗಳು {n} / {total}, {label}',
  'ofAmount': '{amount} ರಲ್ಲಿ',
  'paidOfTotal': '{total} ರಲ್ಲಿ {paid} ಜನ ಪಾವತಿಸಿದ್ದಾರೆ',
  'collectionNote': 'ಸಂಗ್ರಹ {day} {month}, {note}',
  'takesPotName': 'ಚೀಟಿ ಪಡೆಯುವವರು: {name}',
  'yourName': 'ನಿಮ್ಮ ಹೆಸರು',
  'save': 'ಉಳಿಸಿ',
  'cancel': 'ರದ್ದುಮಾಡಿ',
  'close': 'ಮುಚ್ಚಿ',
  'yes': 'ಹೌದು',
  'tryAgain': 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
  'language': 'ಭಾಷೆ',
  'languagePhone': 'ಫೋನಿನ ಭಾಷೆ',
  'agoJustNow': 'ಈಗಷ್ಟೇ',
  'agoMinutes': '{n} ನಿಮಿಷಗಳ ಹಿಂದೆ',
  'agoToday': 'ಇಂದು, {time}',
  'agoYesterday': 'ನಿನ್ನೆ, {time}',
  'am': 'AM',
  'pm': 'PM',
  'andJoin': '{first} ಮತ್ತು {last}',
  'slotN': 'ಸ್ಲಾಟ್ {n}',
  'someone': 'ಯಾರೋ',
  'shareHalf': '½ ಪಾಲು',
  'shareThird': '⅓ ಪಾಲು',
  'shareQuarter': '¼ ಪಾಲು',
  'shareAmount': '{amount} ಪಾಲು',
  'noteInDays': 'ಇನ್ನು {n} ದಿನಗಳಲ್ಲಿ',
  'noteTomorrow': 'ನಾಳೆ',
  'noteToday': 'ಇಂದು',
  'noteDaysLeft': 'ಪಾವತಿಸಲು ಇನ್ನು {n} ದಿನ',
  'noteLastDayTomorrow': 'ಕೊನೆಯ ದಿನ ನಾಳೆ',
  'notePayToday': 'ಇಂದು ಮಧ್ಯರಾತ್ರಿಯೊಳಗೆ ಪಾವತಿಸಿ',
  'noteDeadlinePassed': 'ಕೊನೆಯ ದಿನಾಂಕ ಮುಗಿದಿದೆ',
  'errSessionEnded': 'ನಿಮ್ಮ ಸೈನ್ ಇನ್ ಮುಗಿದಿದೆ. ಮತ್ತೆ ಸೈನ್ ಇನ್ ಮಾಡಿ.',
  'errSignInAgain': 'ಮತ್ತೆ ಸೈನ್ ಇನ್ ಮಾಡಿ.',
  'errOffline': 'ಆಫ್‌ಲೈನ್.',
  'errTimeout': 'ಸರ್ವರ್ ಉತ್ತರಿಸಲು ತುಂಬಾ ಸಮಯ ತೆಗೆದುಕೊಂಡಿತು. ಸಂಪರ್ಕ ಪರಿಶೀಲಿಸಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
  'errNoConnection': 'ಸಂಪರ್ಕವಿಲ್ಲ. ಇಂಟರ್ನೆಟ್ ಪರಿಶೀಲಿಸಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
  'errServer': 'Kuree ಸರ್ವರ್‌ನಲ್ಲಿ ಸಮಸ್ಯೆಯಾಗಿದೆ. ಒಂದು ನಿಮಿಷದ ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
  'errStatus': 'ಏನೋ ತಪ್ಪಾಗಿದೆ ({status}).',
  'errNotOnWhatsApp': 'ಈ ಸಂಖ್ಯೆ WhatsApp ನಲ್ಲಿ ಇಲ್ಲ.',
  'errCouldNotSend': 'ಕೋಡ್ ಕಳುಹಿಸಲು ಆಗಲಿಲ್ಲ. ಒಂದು ನಿಮಿಷದ ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
  'errTooMany': 'ತುಂಬಾ ಪ್ರಯತ್ನಗಳು. ಒಂದು ನಿಮಿಷ ಕಾದು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
  'errWrongCode': 'ಆ ಕೋಡ್ ತಪ್ಪಾಗಿದೆ ಅಥವಾ ಅವಧಿ ಮುಗಿದಿದೆ. ಹೊಸದನ್ನು ಕೇಳಿ.',
  'errPasswordMismatch': 'ಆ ಇಮೇಲ್ ಮತ್ತು ಪಾಸ್‌ವರ್ಡ್ ಹೊಂದುತ್ತಿಲ್ಲ.',
  'errPhoneCountry': 'ದೇಶದ ಕೋಡ್ ಸಹಿತ ನಿಮ್ಮ WhatsApp ಸಂಖ್ಯೆ ನಮೂದಿಸಿ.',
  'errEmailLooksWrong': 'ಆ ಇಮೇಲ್ ಸರಿಯಾಗಿ ಕಾಣುತ್ತಿಲ್ಲ.',
  'errSignInNotFinished': 'ಸೈನ್ ಇನ್ ಪೂರ್ಣಗೊಳ್ಳಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
  'errFile': 'ಈಗ ಫೈಲ್ ತಯಾರಿಸಲು ಆಗಲಿಲ್ಲ. ಒಂದು ನಿಮಿಷದ ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
  'msgReminder': 'ನಮಸ್ಕಾರ {name}, ಒಂದು ಜ್ಞಾಪನೆ: ನಿಮ್ಮ {chit} ತಿಂಗಳು {n} ({label}) ಕಂತು {amount}, {day}ನೇ ತಾರೀಖು ಮಧ್ಯರಾತ್ರಿಯೊಳಗೆ ಪಾವತಿಸಬೇಕು.',
  'msgReminderFrom': 'ನಮಸ್ಕಾರ {name}, {group} ಕಡೆಯಿಂದ ಜ್ಞಾಪನೆ: ನಿಮ್ಮ {chit} ತಿಂಗಳು {n} ({label}) ಕಂತು {amount}, {day}ನೇ ತಾರೀಖು ಮಧ್ಯರಾತ್ರಿಯೊಳಗೆ ಪಾವತಿಸಬೇಕು.',
  'msgFineAfter': ' ಅದರ ನಂತರ {fine} ತಡ ದಂಡವಿದೆ.',
  'msgThanks': ' ಧನ್ಯವಾದಗಳು.',
  'msgPaidHead': '{month} : ಪಾವತಿಸಿದವರು',
  'msgDueHead': '{month} : ಇನ್ನೂ ಪಾವತಿಸದವರು',
  'msgDrawResult': '{chit}, ತಿಂಗಳು {n} ({label})\nಬಾಟಲಿಯಿಂದ ಬಂದದ್ದು: {slot}. {name}\n{pot} ಚೀಟಿ ಮೊತ್ತ ಇವರಿಗೆ.\nಬಾಟಲಿಯಲ್ಲಿ {count} ಹೆಸರುಗಳಿದ್ದವು. ಡ್ರಾ ಆದದ್ದು {when}.',
  'savedMembersSee': 'ಉಳಿಸಲಾಗಿದೆ. ಸದಸ್ಯರು ಈಗ ನೋಡಬಹುದು.',
  'conflictTitle': 'ಬೇರೊಬ್ಬರು ಇದನ್ನು ಉಳಿಸಿದ್ದಾರೆ',
  'conflictText': 'ಸ್ವಲ್ಪ ಮುಂಚೆ ಇನ್ನೊಬ್ಬ ನಿರ್ವಾಹಕರು ಈ ಚೀಟಿಯನ್ನು ಉಳಿಸಿದರು. ಅವರ ಬದಲಾವಣೆ ನೋಡಲು ಮರುಲೋಡ್ ಮಾಡಿ, ನಂತರ ನಿಮ್ಮದನ್ನು ಮತ್ತೆ ಮಾಡಿ.',
  'reload': 'ಮರುಲೋಡ್',
  'nobodyYet': 'ಇನ್ನೂ ಯಾರೂ ಇಲ್ಲ',
  'clearChoice': 'ಆಯ್ಕೆ ತೆಗೆಯಿರಿ',
  'takesPotInMonth': 'ತಿಂಗಳು {n} ರಲ್ಲಿ ಚೀಟಿ ಪಡೆಯುವವರು',
  'allSlotsTaken': 'ಎಲ್ಲಾ ಸ್ಲಾಟ್‌ಗಳೂ ಈಗಾಗಲೇ ಚೀಟಿ ಪಡೆದಿವೆ.',
  'onlyOneLeft': '{name} ಮಾತ್ರ ಉಳಿದಿದ್ದಾರೆ, ಆದ್ದರಿಂದ ಡ್ರಾ ಮಾಡಲು ಏನೂ ಇಲ್ಲ. ಆಯ್ಕೆಮಾಡಿ ಬಳಸಿ.',
  'savedMonthGoesTo': 'ಉಳಿಸಲಾಗಿದೆ. ತಿಂಗಳು {n} {name} ಅವರಿಗೆ.',
  'drawDonePressSave': 'ಡ್ರಾ ಮುಗಿಯಿತು. ಪ್ರಕಟಿಸಲು ಉಳಿಸಿ ಒತ್ತಿ.',
  'numberAddedPressSave': 'ಸಂಖ್ಯೆ ಸೇರಿಸಲಾಗಿದೆ. ಇಟ್ಟುಕೊಳ್ಳಲು ಉಳಿಸಿ ಒತ್ತಿ.',
  'slotsFromNames': 'ಕೆಳಗೆ ಹೆಸರುಗಳನ್ನು ಸೇರಿಸಿ. ಪ್ರತಿ ಹೆಸರು ಒಂದು ಸ್ಲಾಟ್, ಪ್ರತಿ ಸ್ಲಾಟ್‌ಗೆ ಒಂದು ತಿಂಗಳು.',
  'fineChip': 'ತಡ ದಂಡ {fine}',
  'fineEach': 'ಪ್ರತಿ ತಡ ಪಾವತಿಗೆ {fine}',
  'addLateFine': 'ತಡ ದಂಡ ಸೇರಿಸಿ',
  'fineSheetText': 'ಪ್ರತಿ ತಡ ಪಾವತಿಗೆ ಆ ತಿಂಗಳ ಚೀಟಿ ಮೊತ್ತಕ್ಕೆ ಸೇರುತ್ತದೆ. ಈಗಾಗಲೇ ಗುರುತಿಸಿದ ದಂಡಗಳು ಅದೇ ಮೊತ್ತದಲ್ಲಿ ಉಳಿಯುತ್ತವೆ.',
  'fineChangedPressSave': 'ತಡ ದಂಡ ಈಗ {fine}. ಇಟ್ಟುಕೊಳ್ಳಲು ಉಳಿಸಿ ಒತ್ತಿ.',
  'fineOffPressSave': 'ಇನ್ನು ಮುಂದೆ ತಡ ದಂಡ ಇಲ್ಲ. ಇಟ್ಟುಕೊಳ್ಳಲು ಉಳಿಸಿ ಒತ್ತಿ.',
  'newLinkTitle': 'ಹೊಸ ಲಿಂಕ್ ಮಾಡಬೇಕೆ?',
  'newLinkText': 'ಹಳೆಯ ಲಿಂಕ್ ತಕ್ಷಣ ಕೆಲಸ ನಿಲ್ಲಿಸುತ್ತದೆ. ಹೊಸದನ್ನು ಗುಂಪಿನಲ್ಲಿ ಹಂಚಿಕೊಳ್ಳಿ.',
  'newLinkYes': 'ಹೊಸ ಲಿಂಕ್ ಮಾಡಿ',
  'makingSheet': 'ಸ್ಪ್ರೆಡ್‌ಶೀಟ್ ತಯಾರಾಗುತ್ತಿದೆ…',
  'saveFirstTitle': 'ಮೊದಲು ಉಳಿಸಬೇಕೆ?',
  'saveFirstText': 'ಚೀಟಿಯನ್ನು ಬದಲಿಸುವ ಮೊದಲು ಈ ತಿಂಗಳ ಬದಲಾವಣೆಗಳನ್ನು ಉಳಿಸಿ.',
  'deleteChitTitle': '{name} ಅಳಿಸಬೇಕೆ?',
  'deleteChitText': 'ಚೀಟಿ, ಅದರ ಇತಿಹಾಸ ಮತ್ತು ಸದಸ್ಯರ ಲಿಂಕ್ ಶಾಶ್ವತವಾಗಿ ಅಳಿಸಲಾಗುತ್ತದೆ. ಇದನ್ನು ಹಿಂಪಡೆಯಲು ಆಗದು.',
  'delete': 'ಅಳಿಸಿ',
  'membersLink': 'ಸದಸ್ಯರ ಲಿಂಕ್',
  'membersLinkSub': 'ಗುಂಪಿನಲ್ಲಿ ಹಂಚಿಕೊಳ್ಳಿ',
  'drawRest': 'ಉಳಿದದ್ದನ್ನು ಡ್ರಾ ಮಾಡಿ',
  'drawRestSub': 'ಇನ್ನೂ ತೆರೆದಿರುವ ಎಲ್ಲಾ ತಿಂಗಳುಗಳನ್ನು ಬೆರೆಸಿ',
  'spreadsheet': 'ಸ್ಪ್ರೆಡ್‌ಶೀಟ್',
  'spreadsheetSub': 'ಪ್ರತಿ ತಿಂಗಳು, ಪ್ರತಿ ಸದಸ್ಯ',
  'history': 'ಇತಿಹಾಸ',
  'historySub': 'ಹಿಂದಿನ ಎಲ್ಲಾ ಆವೃತ್ತಿಗಳು',
  'admins': 'ನಿರ್ವಾಹಕರು',
  'adminsSub': 'ಈ ಚೀಟಿ ನಡೆಸುವವರು',
  'editChit': 'ಚೀಟಿ ಬದಲಿಸಿ',
  'editChitSub': 'ಹೆಸರು, ಮೊತ್ತಗಳು, ಕರೆನ್ಸಿ, ದಿನಾಂಕಗಳು, ಸ್ಲಾಟ್‌ಗಳು, ಜನರು',
  'deleteChit': 'ಚೀಟಿ ಅಳಿಸಿ',
  'leaveTitle': 'ಉಳಿಸದೆ ಹೊರಡಬೇಕೆ?',
  'leaveText': 'ಈ ತಿಂಗಳ ನಿಮ್ಮ ಬದಲಾವಣೆಗಳು ಇನ್ನೂ ಉಳಿಸಿಲ್ಲ.',
  'leave': 'ಹೊರಡಿ',
  'more': 'ಇನ್ನಷ್ಟು',
  'saveChangesFirst': 'ಮೊದಲು ನಿಮ್ಮ ಬದಲಾವಣೆಗಳನ್ನು ಉಳಿಸಿ.',
  'historyKept': 'ಪ್ರತಿ ಉಳಿಕೆಯನ್ನೂ ಇತಿಹಾಸದಲ್ಲಿ ಇಡಲಾಗುತ್ತದೆ, ಏನೂ ಕಳೆದುಹೋಗದು.',
  'lastSavedBy': 'ಕೊನೆಯದಾಗಿ ಉಳಿಸಿದವರು {name}, {when}',
  'notSavedYet': 'ಇನ್ನೂ ಉಳಿಸಿಲ್ಲ',
  'undo': 'ರದ್ದುಗೊಳಿಸಿ',
  'prevMonth': 'ಹಿಂದಿನ ತಿಂಗಳು',
  'nextMonth': 'ಮುಂದಿನ ತಿಂಗಳು',
  'prevYear': 'ಹಿಂದಿನ ವರ್ಷ',
  'nextYear': 'ಮುಂದಿನ ವರ್ಷ',
  'monthNLabel': 'ತಿಂಗಳು {n}, {label}',
  'collectedOf': '{pot} ರಲ್ಲಿ ಸಂಗ್ರಹವಾಗಿದೆ',
  'collectedOfFines': '{pot} ರಲ್ಲಿ ಸಂಗ್ರಹವಾಗಿದೆ, ಜೊತೆಗೆ {fines} ದಂಡ',
  'toGo': 'ಇನ್ನು {n} ಜನ',
  'everyonePaid': 'ಎಲ್ಲರೂ ಪಾವತಿಸಿದ್ದಾರೆ',
  'heroCollection': 'ಸಂಗ್ರಹ {day} {month}, {payDay} {payMonth} ರೊಳಗೆ ಪಾವತಿಸಿ: {note}',
  'month': 'ತಿಂಗಳು',
  'settled': 'ಮುಗಿದಿದೆ',
  'inProgress': 'ನಡೆಯುತ್ತಿದೆ',
  'inProgressTakes': 'ನಡೆಯುತ್ತಿದೆ, ಚೀಟಿ {name} ಅವರಿಗೆ',
  'upcoming': 'ಮುಂಬರುವ',
  'upcomingTakes': 'ಮುಂಬರುವ, ಚೀಟಿ {name} ಅವರಿಗೆ',
  'winnerAmountFine': '{total} (ಚೀಟಿ ಮೊತ್ತ ಮತ್ತು {fine} ದಂಡ)',
  'pickedFromBottle': '{amount}, ಬಾಟಲಿಯಿಂದ ಆಯ್ಕೆ',
  'takesPotThisMonth': 'ಈ ತಿಂಗಳು ಚೀಟಿ ಪಡೆಯುವವರು',
  'notDecided': 'ಇನ್ನೂ ನಿರ್ಧರಿಸಿಲ್ಲ',
  'bottleDraw': 'ಬಾಟಲಿ ಡ್ರಾ',
  'choose': 'ಆಯ್ಕೆಮಾಡಿ',
  'change': 'ಬದಲಿಸಿ',
  'allPaid': 'ಎಲ್ಲರೂ ಪಾವತಿಸಿದ್ದಾರೆ',
  'reminders': 'ಜ್ಞಾಪನೆಗಳು',
  'everyonePaidFor': 'ತಿಂಗಳು {n} ಕ್ಕೆ ಎಲ್ಲರೂ ಪಾವತಿಸಿದ್ದಾರೆ',
  'showList': 'ತೋರಿಸಿ',
  'hideList': 'ಮರೆಮಾಡಿ',
  'filterAll': 'ಎಲ್ಲರೂ {n}',
  'filterDue': 'ಪಾವತಿ ಬಾಕಿ {n}',
  'filterPaid': 'ಪಾವತಿಸಿದವರು {n}',
  'tickHelp': 'ಯಾರಾದರೂ ಪಾವತಿಸಿದಾಗ ಟಿಕ್ ಒತ್ತಿ. ಕೊನೆಯ ದಿನಾಂಕದ ನಂತರ ಪಾವತಿಸಿದ್ದರೆ ತಡ ಒತ್ತಿ.',
  'everyonePaidMonth': 'ತಿಂಗಳು {n} ಕ್ಕೆ ಎಲ್ಲರೂ ಪಾವತಿಸಿದ್ದಾರೆ.',
  'nobodyPaidMonth': 'ತಿಂಗಳು {n} ಕ್ಕೆ ಇನ್ನೂ ಯಾರೂ ಪಾವತಿಸಿಲ್ಲ.',
  'statusPaid': 'ಪಾವತಿಸಿದ್ದು {amount}',
  'statusPending': 'ಬಾಕಿ {amount}',
  'statusLateFine': '{status}, ತಡ ದಂಡ {fine}',
  'monthN': 'ತಿಂಗಳು {n}',
  'semPaid': 'ಪಾವತಿಸಿದ್ದಾರೆ: {name}',
  'semLate': 'ತಡ ದಂಡ, {name}',
  'lateButton': 'ತಡ',
  'couldNotOpen': 'ಅದನ್ನು ತೆರೆಯಲು ಆಗಲಿಲ್ಲ. WhatsApp ಇನ್‌ಸ್ಟಾಲ್ ಆಗಿದೆಯೇ?',
  'copied': 'ನಕಲಿಸಲಾಗಿದೆ',
  'drawTitle': 'ತಿಂಗಳು {n} ಡ್ರಾ',
  'drawSubtitle': '{label}, ಚೀಟಿ ಮೊತ್ತ {pot}',
  'savedToPhotos': 'ನಿಮ್ಮ ಫೋಟೋಗಳಲ್ಲಿ ಉಳಿಸಲಾಗಿದೆ.',
  'videoFailed': 'ಈ ಫೋನಿನಲ್ಲಿ ವೀಡಿಯೊ ತಯಾರಿಸಲು ಆಗಲಿಲ್ಲ.',
  'drawShareTitle': '{title}, ತಿಂಗಳು {n} ಡ್ರಾ',
  'stopDrawTitle': 'ಡ್ರಾ ನಿಲ್ಲಿಸಬೇಕೆ?',
  'nothingSaved': 'ಏನೂ ಉಳಿಸುವುದಿಲ್ಲ.',
  'stop': 'ನಿಲ್ಲಿಸಿ',
  'closeUnsavedTitle': 'ಉಳಿಸದೆ ಮುಚ್ಚಬೇಕೆ?',
  'winnerNotSaved': 'ಚೀಟಿ ಪಡೆದವರನ್ನು ಇನ್ನೂ ಉಳಿಸಿಲ್ಲ.',
  'slipsGoIn': '{n} ಚೀಟಿಗಳು ಬಾಟಲಿಗೆ, ಇನ್ನೂ ಚೀಟಿಗಾಗಿ ಕಾಯುತ್ತಿರುವ ಪ್ರತಿ ಸ್ಲಾಟ್‌ಗೆ ಒಂದು.',
  'recordHint': 'ಈ ಪರದೆಯ ಮೇಲೆ ಇನ್ನೊಂದು ಫೋನ್ ಹಿಡಿದು ರೆಕಾರ್ಡ್ ಆರಂಭಿಸಿ, ನಂತರ ಡ್ರಾ ಆರಂಭಿಸಿ ಒತ್ತಿ. 3 ರಿಂದ ಎಣಿಕೆ ಶುರುವಾಗುತ್ತದೆ.',
  'musicSound': 'ಸಂಗೀತ ಮತ್ತು ಧ್ವನಿಗಳು',
  'gettingReady': 'ಸಿದ್ಧವಾಗುತ್ತಿದೆ',
  'startDraw': 'ಡ್ರಾ ಆರಂಭಿಸಿ',
  'takesPotFor': 'ತಿಂಗಳು {n}, {label}: ಚೀಟಿ ಇವರಿಗೆ.',
  'saved': 'ಉಳಿಸಲಾಗಿದೆ',
  'saveAsWinner': 'ತಿಂಗಳು {n} ರ ಚೀಟಿ ಪಡೆದವರಾಗಿ ಉಳಿಸಿ',
  'makingVideo': 'ವೀಡಿಯೊ ತಯಾರಾಗುತ್ತಿದೆ {pct}%',
  'shareVideo': 'ವೀಡಿಯೊ ಹಂಚಿಕೊಳ್ಳಿ',
  'saveVideo': 'ವೀಡಿಯೊ ಉಳಿಸಿ',
  'sendResultWa': 'ಫಲಿತಾಂಶವನ್ನು WhatsApp ನಲ್ಲಿ ಕಳುಹಿಸಿ',
  'drawGetReady': 'ಸಿದ್ಧರಾಗಿ',
  'drawStartsSoon': 'ಡ್ರಾ ಸ್ವಲ್ಪ ಹೊತ್ತಿನಲ್ಲಿ ಆರಂಭ',
  'drawWriting': 'ಪ್ರತಿ ಹೆಸರನ್ನೂ ಬರೆಯುತ್ತಿದೆ',
  'drawWritingSub': 'ಚೀಟಿಗಾಗಿ ಕಾಯುತ್ತಿರುವ ಪ್ರತಿ ಸ್ಲಾಟ್‌ಗೆ ಒಂದು ಚೀಟಿ',
  'drawInto': 'ಬಾಟಲಿಗೆ',
  'drawClosing': 'ಬಾಟಲಿ ಮುಚ್ಚುತ್ತಿದೆ',
  'drawShaking': 'ಅಲುಗಾಡಿಸುತ್ತಿದೆ',
  'drawShakingSub': 'ಪ್ರತಿ ಚೀಟಿಗೂ ಸಮಾನ ಅವಕಾಶ',
  'drawPicking': 'ಒಂದನ್ನು ಆರಿಸುತ್ತಿದೆ',
  'drawFooterDrawn': 'ಬಾಟಲಿಯಲ್ಲಿ {n} ಹೆಸರುಗಳು. ಡ್ರಾ {when}',
  'drawFooterNow': 'ಬಾಟಲಿಯಲ್ಲಿ {n} ಹೆಸರುಗಳು. {when}',
  'everyMonthTaken': 'ಮುಂದಿನ ತಿಂಗಳಿನಿಂದ ಎಲ್ಲಾ ತಿಂಗಳುಗಳಿಗೂ ಈಗಾಗಲೇ ಚೀಟಿ ಪಡೆಯುವವರಿದ್ದಾರೆ.',
  'drawRestIntro': 'ಇನ್ನೂ ಚೀಟಿ ಪಡೆಯಬೇಕಾದ {slots} ಸ್ಲಾಟ್‌ಗಳು, {from} ರಿಂದ {months} ತಿಂಗಳುಗಳಲ್ಲಿ. ಪ್ರತಿ ಸ್ಲಾಟ್ ಒಂದು ಡ್ರಾ.',
  'drawRestIntroOne': 'ಇನ್ನೂ ಚೀಟಿ ಪಡೆಯಬೇಕಾದ {slots} ಸ್ಲಾಟ್‌ಗಳು, {from} ರಿಂದ 1 ತಿಂಗಳಲ್ಲಿ. ಪ್ರತಿ ಸ್ಲಾಟ್ ಒಂದು ಡ್ರಾ.',
  'noSlotLeft': 'ಸ್ಲಾಟ್ ಉಳಿದಿಲ್ಲ',
  'notPlaced': 'ಸೇರಿಸಲಾಗಿಲ್ಲ (ತಿಂಗಳು ಉಳಿದಿಲ್ಲ): {list}',
  'useThisOrder': 'ಈ ಕ್ರಮ ಬಳಸಿ',
  'useOrderTitle': 'ಈ ಕ್ರಮ ಬಳಸಬೇಕೆ?',
  'useOrderText': 'ಇದು {n} ತಿಂಗಳುಗಳಿಗೆ ಚೀಟಿ ಪಡೆಯುವವರನ್ನು ನಿಗದಿಪಡಿಸುತ್ತದೆ. ಉಳಿಸುವ ಮೊದಲು ಯಾವುದೇ ತಿಂಗಳನ್ನು ಕೈಯಾರೆ ಬದಲಿಸಬಹುದು.',
  'useIt': 'ಬಳಸಿ',
  'shuffleAgain': 'ಮತ್ತೆ ಬೆರೆಸಿ',
  'remindersTitle': 'ಜ್ಞಾಪನೆಗಳು, ತಿಂಗಳು {n}',
  'shareListInGroup': 'ಪಟ್ಟಿಯನ್ನು ಗುಂಪಿನಲ್ಲಿ ಹಂಚಿಕೊಳ್ಳಿ',
  'nobodyToRemind': 'ಎಲ್ಲರೂ ಪಾವತಿಸಿದ್ದಾರೆ, ನೆನಪಿಸಲು ಯಾರೂ ಇಲ್ಲ.',
  'remindEach': 'ಅಥವಾ ಪ್ರತಿಯೊಬ್ಬರಿಗೂ ಸಂದೇಶ ಕಳುಹಿಸಿ. {rest}',
  'everyoneHasNumber': 'ಇಲ್ಲಿ ಎಲ್ಲರಿಗೂ ಸಂಖ್ಯೆ ಇದೆ.',
  'noNumberOne': '1 ಜನರಿಗೆ ಇನ್ನೂ ಸಂಖ್ಯೆ ಇಲ್ಲ.',
  'noNumberMany': '{n} ಜನರಿಗೆ ಇನ್ನೂ ಸಂಖ್ಯೆ ಇಲ್ಲ.',
  'noNumberYet': 'ಇನ್ನೂ ಸಂಖ್ಯೆ ಇಲ್ಲ',
  'dueMonth': '{amount} ಬಾಕಿ, ತಿಂಗಳು {n}',
  'addNumber': 'ಸಂಖ್ಯೆ ಸೇರಿಸಿ',
  'sent': 'ಕಳುಹಿಸಲಾಗಿದೆ',
  'remind': 'ನೆನಪಿಸಿ',
  'couldNotOpenWa': 'WhatsApp ತೆರೆಯಲು ಆಗಲಿಲ್ಲ.',
  'numberTitle': '{name} ಅವರ ಸಂಖ್ಯೆ',
  'enterWaNumber': 'WhatsApp ಸಂಖ್ಯೆ ನಮೂದಿಸಿ.',
  'waNumberHint': 'WhatsApp ಸಂಖ್ಯೆ',
  'numberUse': 'ಜ್ಞಾಪನೆಗಳಿಗೆ ಮಾತ್ರ. ಸದಸ್ಯರು ಇದನ್ನು ಎಂದಿಗೂ ನೋಡುವುದಿಲ್ಲ.',
  'saveNumber': 'ಸಂಖ್ಯೆ ಉಳಿಸಿ',
  'linkExplain': 'ಸದಸ್ಯರು ಇದನ್ನು ಯಾವುದೇ ಬ್ರೌಸರ್‌ನಲ್ಲಿ ತೆರೆಯಬಹುದು. ಯಾರು ಪಾವತಿಸಿದರು, ದಂಡಗಳು, ಯಾರು ಚೀಟಿ ಪಡೆದರು, ಮುಂದೇನು ಎಂದು ನೋಡಬಹುದು. ಆ್ಯಪ್ ಅಥವಾ ಸೈನ್ ಇನ್ ಬೇಕಿಲ್ಲ, ಫೋನ್ ಸಂಖ್ಯೆಗಳು ಕಾಣುವುದಿಲ್ಲ.',
  'copy': 'ನಕಲಿಸಿ',
  'linkCopied': 'ಲಿಂಕ್ ನಕಲಿಸಲಾಗಿದೆ',
  'whatsapp': 'WhatsApp',
  'open': 'ತೆರೆಯಿರಿ',
  'share': 'ಹಂಚಿಕೊಳ್ಳಿ',
  'errNeedName': 'ಚೀಟಿಗೆ ಒಂದು ಹೆಸರು ಕೊಡಿ, ಉದಾ. 5K ಚೀಟಿ.',
  'errNeedShare': 'ಪ್ರತಿ ಸ್ಲಾಟ್ ತಿಂಗಳಿಗೆ ಎಷ್ಟು ಪಾವತಿಸುತ್ತದೆ ಎಂದು ನಮೂದಿಸಿ.',
  'errSlotName': 'ಸ್ಲಾಟ್ {n} ಕ್ಕೆ ಒಂದು ಹೆಸರು ಬೇಕು.',
  'errPartsSum': 'ಸ್ಲಾಟ್ {n}: ಪಾಲುಗಳ ಒಟ್ಟು {total}, ಆದರೆ ಒಂದು ಸ್ಲಾಟ್ ಪಾವತಿಸುವುದು {share}.',
  'errPartAmount': 'ಸ್ಲಾಟ್ {n}: ಪ್ರತಿಯೊಬ್ಬರು ಪಾವತಿಸುವ ಮೊತ್ತ ನಮೂದಿಸಿ.',
  'errFewerSlots': 'ತಿಂಗಳು {n} ರಲ್ಲಿ ಈಗಾಗಲೇ ಪಾವತಿಗಳು ಅಥವಾ ಚೀಟಿ ಪಡೆದವರು ಇದ್ದಾರೆ, ಆದ್ದರಿಂದ ಚೀಟಿಗೆ {n} ಕ್ಕಿಂತ ಕಡಿಮೆ ಸ್ಲಾಟ್‌ಗಳು ಇರಲಾರವು.',
  'errTakerSlot': 'ಸ್ಲಾಟ್ {slot} ತಿಂಗಳು {n} ರಲ್ಲಿ ಚೀಟಿ ಪಡೆದಿದೆ, ಆದ್ದರಿಂದ ಚೀಟಿಗೆ ಕನಿಷ್ಠ {slot} ಸ್ಲಾಟ್‌ಗಳು ಬೇಕು.',
  'errConflictEditor': 'ಸ್ವಲ್ಪ ಮುಂಚೆ ಇನ್ನೊಬ್ಬ ನಿರ್ವಾಹಕರು ಈ ಚೀಟಿಯನ್ನು ಉಳಿಸಿದರು. ಹಿಂದೆ ಹೋಗಿ ಮರುಲೋಡ್ ಮಾಡಿ, ನಿಮ್ಮ ಬದಲಾವಣೆಗಳನ್ನು ಮತ್ತೆ ಮಾಡಿ.',
  'firstMonth': 'ಮೊದಲ ತಿಂಗಳು',
  'shorterMonths': 'ಕಡಿಮೆ ದಿನಗಳ ತಿಂಗಳುಗಳಲ್ಲಿ ಕೊನೆಯ ದಿನ',
  'currency': 'ಕರೆನ್ಸಿ',
  'sectionChit': 'ಚೀಟಿ',
  'sectionMoney': 'ಹಣ',
  'sectionDates': 'ದಿನಾಂಕಗಳು',
  'fieldName': 'ಹೆಸರು',
  'nameHint': '5K ಚೀಟಿ',
  'fieldGroup': 'ಗುಂಪು',
  'groupHint': 'ರಿವರ್‌ಸೈಡ್',
  'eachSlotPays': 'ಪ್ರತಿ ಸ್ಲಾಟ್ ತಿಂಗಳಿಗೆ ಪಾವತಿಸುವುದು',
  'lateFine': 'ತಡ ದಂಡ',
  'fineNone': 'ಇಲ್ಲ',
  'slots': 'ಸ್ಲಾಟ್‌ಗಳು',
  'fewerSlots': 'ಸ್ಲಾಟ್ ಕಡಿಮೆಮಾಡಿ',
  'moreSlots': 'ಸ್ಲಾಟ್ ಹೆಚ್ಚಿಸಿ',
  'potSummary': 'ತಿಂಗಳಿಗೆ {pot} ಚೀಟಿ ಮೊತ್ತ, {n} ತಿಂಗಳುಗಳಿಗೆ',
  'potSummaryNone': 'ಪ್ರತಿ ತಿಂಗಳು ಒಂದು ಸ್ಲಾಟ್ ಚೀಟಿ ಪಡೆಯುತ್ತದೆ, {n} ತಿಂಗಳುಗಳಿಗೆ',
  'collectionDay': 'ಸಂಗ್ರಹದ ದಿನ',
  'everyMonthDay': 'ಪ್ರತಿ ತಿಂಗಳ {day}ನೇ ತಾರೀಖು',
  'lastDayToPay': 'ಪಾವತಿಸಲು ಕೊನೆಯ ದಿನ',
  'byMidnight': '{day}ನೇ ತಾರೀಖು, ಮಧ್ಯರಾತ್ರಿಯೊಳಗೆ',
  'byMidnightNext': 'ಮುಂದಿನ ತಿಂಗಳ {day}ನೇ ತಾರೀಖು, ಮಧ್ಯರಾತ್ರಿಯೊಳಗೆ',
  'oneNamePerSlot': 'ಒಂದು ಸ್ಲಾಟ್‌ಗೆ ಒಂದು ಹೆಸರು',
  'numbersForReminders': 'ಜ್ಞಾಪನೆಗಳಿಗೆ ಸಂಖ್ಯೆಗಳು',
  'countOf': '{a} / {b}',
  'addNamesFirst': 'ಮೊದಲು ಸ್ಲಾಟ್‌ಗಳಿಗೆ ಹೆಸರುಗಳನ್ನು ಸೇರಿಸಿ.',
  'numbersNote': 'ಸಂಖ್ಯೆಗಳು WhatsApp ಜ್ಞಾಪನೆಗಳಿಗೆ ಮಾತ್ರ. ಸದಸ್ಯರ ಲಿಂಕ್‌ನಲ್ಲಿ ಅವು ಎಂದಿಗೂ ಕಾಣುವುದಿಲ್ಲ.',
  'startTheChit': 'ಚೀಟಿ ಆರಂಭಿಸಿ',
  'saveChanges': 'ಬದಲಾವಣೆಗಳನ್ನು ಉಳಿಸಿ',
  'nameN': 'ಹೆಸರು {n}',
  'remove': 'ತೆಗೆಯಿರಿ',
  'splitSlot': 'ಈ ಸ್ಲಾಟ್ ಹಂಚಿ',
  'addPerson': 'ಒಬ್ಬರನ್ನು ಸೇರಿಸಿ',
  'somethingWrong': 'ಏನೋ ತಪ್ಪಾಗಿದೆ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
  'enterYourWa': 'ನಿಮ್ಮ WhatsApp ಸಂಖ್ಯೆ ನಮೂದಿಸಿ.',
  'enterCode': '6 ಅಂಕಿಯ ಕೋಡ್ ನಮೂದಿಸಿ.',
  'enterEmailPassword': 'ಇಮೇಲ್ ಮತ್ತು ಪಾಸ್‌ವರ್ಡ್ ನಮೂದಿಸಿ.',
  'subPhoneCode': 'ಕೋಡ್‌ಗಾಗಿ WhatsApp ನೋಡಿ.',
  'subEmailCode': 'ಕೋಡ್‌ಗಾಗಿ ನಿಮ್ಮ ಇಮೇಲ್ ನೋಡಿ.',
  'subPhone': 'ನಿಮ್ಮ WhatsApp ಸಂಖ್ಯೆಯೊಂದಿಗೆ ಸೈನ್ ಇನ್ ಮಾಡಿ.',
  'subEmail': 'ನಿಮ್ಮ ಇಮೇಲ್‌ನೊಂದಿಗೆ ಸೈನ್ ಇನ್ ಮಾಡಿ.',
  'subStart': 'ನಿಮ್ಮ ಚೀಟಿಯನ್ನು ಫೋನಿನಿಂದಲೇ ನಡೆಸಿ.',
  'privacy': 'ಗೌಪ್ಯತೆ',
  'terms': 'ನಿಯಮಗಳು',
  'continueWa': 'WhatsApp ಮೂಲಕ ಮುಂದುವರಿಯಿರಿ',
  'useEmailInstead': 'ಬದಲಿಗೆ ಇಮೇಲ್ ಬಳಸಿ',
  'phoneHint': 'ಫೋನ್ ಸಂಖ್ಯೆ',
  'sendCodeWa': 'WhatsApp ನಲ್ಲಿ ಕೋಡ್ ಕಳುಹಿಸಿ',
  'codeSentWa': '{to} ಗೆ WhatsApp ನಲ್ಲಿ 6 ಅಂಕಿಯ ಕೋಡ್ ಕಳುಹಿಸಿದ್ದೇವೆ. ಅದು 10 ನಿಮಿಷ ಮಾನ್ಯ.',
  'codeSentEmail': '{to} ಗೆ 6 ಅಂಕಿಯ ಕೋಡ್ ಕಳುಹಿಸಿದ್ದೇವೆ. ಅದು 10 ನಿಮಿಷ ಮಾನ್ಯ.',
  'signIn': 'ಸೈನ್ ಇನ್',
  'sendAgainIn': '{n} ಸೆಕೆಂಡುಗಳಲ್ಲಿ ಮತ್ತೆ ಕಳುಹಿಸಬಹುದು',
  'sendAgain': 'ಮತ್ತೆ ಕಳುಹಿಸಿ',
  'anotherNumber': 'ಬೇರೆ ಸಂಖ್ಯೆ',
  'anotherEmail': 'ಬೇರೆ ಇಮೇಲ್',
  'email': 'ಇಮೇಲ್',
  'emailMeCode': 'ಇಮೇಲ್‌ನಲ್ಲಿ ಕೋಡ್ ಕಳುಹಿಸಿ',
  'useWa': 'WhatsApp ಬಳಸಿ',
  'usePassword': 'ಪಾಸ್‌ವರ್ಡ್ ಬಳಸಿ',
  'password': 'ಪಾಸ್‌ವರ್ಡ್',
  'emailCodeInstead': 'ಬದಲಿಗೆ ಇಮೇಲ್‌ನಲ್ಲಿ ಕೋಡ್ ಕಳುಹಿಸಿ',
  'countryCode': 'ದೇಶದ ಕೋಡ್',
  'signOutTitle': 'ಸೈನ್ ಔಟ್ ಮಾಡಬೇಕೆ?',
  'signOutText': 'ನಿಮ್ಮ ಚೀಟಿಗಳು ಸರ್ವರ್‌ನಲ್ಲಿ ಸುರಕ್ಷಿತವಾಗಿರುತ್ತವೆ. ಅವುಗಳನ್ನು ನೋಡಲು ಮತ್ತೆ ಸೈನ್ ಇನ್ ಮಾಡಿ.',
  'signOut': 'ಸೈನ್ ಔಟ್',
  'deleteAccountTitle': 'ನಿಮ್ಮ ಖಾತೆ ಅಳಿಸಬೇಕೆ?',
  'deleteAccountText': 'ನಿಮ್ಮ Kuree ಖಾತೆ ಮತ್ತು ಹೆಸರು ಅಳಿಸಲಾಗುತ್ತದೆ. ನೀವು ಮಾಲೀಕರಾಗಿರುವ ಚೀಟಿಗಳು ಮುಂದಿನ ನಿರ್ವಾಹಕರಿಗೆ ಹೋಗುತ್ತವೆ. ನೀವು ಮಾತ್ರ ನಡೆಸುವ ಚೀಟಿಗಳು ಅವುಗಳ ಇತಿಹಾಸ ಮತ್ತು ಸದಸ್ಯರ ಲಿಂಕ್‌ಗಳ ಸಹಿತ ಶಾಶ್ವತವಾಗಿ ಅಳಿಸಲಾಗುತ್ತವೆ. ಇದನ್ನು ಹಿಂಪಡೆಯಲು ಆಗದು.',
  'deleteLoginToo': 'ನನ್ನ SkiFi ಲಾಗಿನ್ ಕೂಡ ಅಳಿಸಿ',
  'deleteLoginTooSub': 'ನೀವು ಸೈನ್ ಇನ್ ಮಾಡುವ ಸಂಖ್ಯೆ ಅಥವಾ ಇಮೇಲ್. ಅದನ್ನು ಬಳಸುವ ಇತರ SkiFi ಆ್ಯಪ್‌ಗಳೂ ಅದನ್ನು ಕಳೆದುಕೊಳ್ಳುತ್ತವೆ.',
  'deleteAccount': 'ಖಾತೆ ಅಳಿಸಿ',
  'deleting': 'ಅಳಿಸಲಾಗುತ್ತಿದೆ…',
  'noNameYet': 'ಇನ್ನೂ ಹೆಸರಿಲ್ಲ',
  'edit': 'ಬದಲಿಸಿ',
  'requestFeature': 'ಒಂದು ವೈಶಿಷ್ಟ್ಯ ಕೇಳಿ',
  'featureInbox': 'ವೈಶಿಷ್ಟ್ಯ ವಿನಂತಿಗಳು',
  'contact': 'ಸಂಪರ್ಕಿಸಿ',
  'histPaid': 'ತಿಂಗಳು {n}: {a} ಜನ ಪಾವತಿಸಿದ್ದರು, ನಂತರ {b}',
  'histNoTaker': 'ತಿಂಗಳು {n} ಕ್ಕೆ ಆಗ ಚೀಟಿ ಪಡೆಯುವವರು ಇರಲಿಲ್ಲ',
  'histWentTo': 'ತಿಂಗಳು {n} {name} ಅವರಿಗೆ ಹೋಗಿತ್ತು',
  'histFines': 'ತಿಂಗಳು {n}: {count} ತಡ ದಂಡಗಳು',
  'histSettings': 'ಬೇರೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
  'histPeople': 'ಬೇರೆ ಜನರು ಅಥವಾ ಸ್ಲಾಟ್‌ಗಳು',
  'histSmall': 'ಸಣ್ಣ ಬದಲಾವಣೆಗಳು',
  'histAndMore': 'ಮತ್ತು ಇನ್ನಷ್ಟು',
  'restoreTitle': 'ಈ ಆವೃತ್ತಿಯನ್ನು ಮರಳಿ ತರಬೇಕೆ?',
  'restoreText': '{name} {when} ಬಿಟ್ಟ ಸ್ಥಿತಿಗೆ ಚೀಟಿ ಮರಳುತ್ತದೆ. ಈಗಿರುವುದನ್ನೂ ಇತಿಹಾಸದಲ್ಲಿ ಇಡಲಾಗುತ್ತದೆ, ಆದ್ದರಿಂದ ಇದನ್ನು ರದ್ದುಗೊಳಿಸಬಹುದು.',
  'putItBack': 'ಮರಳಿ ತನ್ನಿ',
  'historyEmpty': 'ಇನ್ನೂ ಹಿಂದಿನ ಆವೃತ್ತಿಗಳಿಲ್ಲ. ಪ್ರತಿ ಉಳಿಕೆ ಒಂದನ್ನು ಸೇರಿಸುತ್ತದೆ.',
  'savedBy': 'ಉಳಿಸಿದವರು {name}',
  'putBack': 'ಮರಳಿಸಿ',
  'addAnAdmin': 'ಒಬ್ಬ ನಿರ್ವಾಹಕರನ್ನು ಸೇರಿಸಿ',
  'adminAdded': 'ಸೇರಿಸಲಾಗಿದೆ. ಸೈನ್ ಇನ್ ಮಾಡಿದಾಗ ಅವರು ಈ ಚೀಟಿಯನ್ನು ನೋಡುತ್ತಾರೆ.',
  'leaveChitTitle': 'ಈ ಚೀಟಿಯಿಂದ ಹೊರಡಬೇಕೆ?',
  'removeAdminTitle': '{name} ಅವರನ್ನು ತೆಗೆಯಬೇಕೆ?',
  'leaveChitText': 'ನಂತರ ನೀವು ಇದನ್ನು ನೋಡಲು ಅಥವಾ ಬದಲಿಸಲು ಆಗುವುದಿಲ್ಲ.',
  'removeAdminText': 'ನಂತರ ಅವರು ಈ ಚೀಟಿಯನ್ನು ನೋಡಲು ಅಥವಾ ಬದಲಿಸಲು ಆಗುವುದಿಲ್ಲ.',
  'makeOwnerTitle': '{name} ಅವರನ್ನು ಮಾಲೀಕರನ್ನಾಗಿ ಮಾಡಬೇಕೆ?',
  'makeOwnerText': 'ಅವರು ನಿರ್ವಾಹಕರನ್ನು ಸೇರಿಸಲು ಮತ್ತು ತೆಗೆಯಲು, ಚೀಟಿ ಅಳಿಸಲು ಸಾಧ್ಯವಾಗುತ್ತದೆ. ನೀವು ನಿರ್ವಾಹಕರಾಗಿ ಮುಂದುವರಿಯುತ್ತೀರಿ.',
  'makeOwner': 'ಮಾಲೀಕರನ್ನಾಗಿ ಮಾಡಿ',
  'ownsNow': 'ಈಗ ಚೀಟಿಯ ಮಾಲೀಕರು {name}.',
  'addAdmin': 'ನಿರ್ವಾಹಕರನ್ನು ಸೇರಿಸಿ',
  'adminsExplain': 'ನಿರ್ವಾಹಕರು ಪಾವತಿಗಳನ್ನು ಗುರುತಿಸುತ್ತಾರೆ, ಡ್ರಾ ನಡೆಸುತ್ತಾರೆ, ಜ್ಞಾಪನೆ ಕಳುಹಿಸುತ್ತಾರೆ. ಮಾಲೀಕರು ನಿರ್ವಾಹಕರನ್ನು ಸೇರಿಸುತ್ತಾರೆ ಮತ್ತು ತೆಗೆಯುತ್ತಾರೆ.',
  'roleOwner': 'ಮಾಲೀಕ',
  'you': 'ನೀವು',
  'leaveChit': 'ಈ ಚೀಟಿಯಿಂದ ಹೊರಡಿ',
  'removeAdmin': 'ನಿರ್ವಾಹಕರನ್ನು ತೆಗೆಯಿರಿ',
  'enterTheirWa': 'ಅವರ WhatsApp ಸಂಖ್ಯೆ ನಮೂದಿಸಿ.',
  'enterTheirEmail': 'ಅವರ ಇಮೇಲ್ ನಮೂದಿಸಿ.',
  'theirName': 'ಅವರ ಹೆಸರು',
  'useEmail': 'ಇಮೇಲ್ ಬಳಸಿ',
  'adminSignInEmail': 'ಚೀಟಿ ನೋಡಲು ಅವರು ಈ ಇಮೇಲ್‌ನೊಂದಿಗೆ Kuree ಗೆ ಸೈನ್ ಇನ್ ಮಾಡಬೇಕು.',
  'adminSignInNumber': 'ಚೀಟಿ ನೋಡಲು ಅವರು ಈ ಸಂಖ್ಯೆಯೊಂದಿಗೆ Kuree ಗೆ ಸೈನ್ ಇನ್ ಮಾಡಬೇಕು.',
  'frTitle': 'ಒಂದು ವೈಶಿಷ್ಟ್ಯ ಕೇಳಿ',
  'frIntroTitle': 'ಏನು ಸಹಾಯವಾಗುತ್ತದೆ ಎಂದು ಹೇಳಿ',
  'frIntroText': 'ಒಂದು ಆಲೋಚನೆ, ಅಡ್ಡಿಯಾಗುವ ಏನಾದರೂ, ನಿಮಗೆ ಬೇಕಾದ ವೈಶಿಷ್ಟ್ಯ. ನಾವು ಪ್ರತಿ ವಿನಂತಿಯನ್ನೂ ಓದುತ್ತೇವೆ.',
  'frFieldTitle': 'ನಿಮ್ಮ ಆಲೋಚನೆ ಕೆಲವು ಪದಗಳಲ್ಲಿ',
  'frFieldTitleHint': 'ಉದಾ.: ಹಿಂದಿನ ದಿನ ಒಂದು ಜ್ಞಾಪನೆ',
  'frFieldDetails': 'ಇನ್ನಷ್ಟು ಹೇಳಿ (ಐಚ್ಛಿಕ)',
  'frFieldDetailsHint': 'ನೀವು ಇದನ್ನು ಹೇಗೆ ಬಳಸುತ್ತೀರಿ? ಇಂದು ಏನಾಗುತ್ತಿದೆ?',
  'frImportance': 'ಇದು ಎಷ್ಟು ಸಹಾಯ ಮಾಡುತ್ತದೆ?',
  'frNice': 'ಇದ್ದರೆ ಒಳ್ಳೆಯದು',
  'frImportant': 'ಮುಖ್ಯ',
  'frMust': 'ಬೇಕೇ ಬೇಕು',
  'frSend': 'ವಿನಂತಿ ಕಳುಹಿಸಿ',
  'frNeedTitle': 'ನಿಮ್ಮ ಆಲೋಚನೆಗೆ ಚಿಕ್ಕ ಶೀರ್ಷಿಕೆ ಕೊಡಿ.',
  'frThanksTitle': 'ಧನ್ಯವಾದಗಳು!',
  'frThanksText': 'ನಿಮ್ಮ ವಿನಂತಿ Kuree ತಂಡವನ್ನು ತಲುಪಿದೆ. ಕೆಳಗೆ ಅದನ್ನು ಗಮನಿಸಬಹುದು.',
  'frSendAnother': 'ಇನ್ನೊಂದು ಕಳುಹಿಸಿ',
  'frYours': 'ನಿಮ್ಮ ವಿನಂತಿಗಳು',
  'frNoneYet': 'ನಿಮ್ಮ ವಿನಂತಿಗಳು ಮತ್ತು ತಂಡದ ನಿರ್ಧಾರ ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತವೆ.',
  'frReply': 'Kuree ತಂಡದಿಂದ',
  'frInboxTitle': 'ವೈಶಿಷ್ಟ್ಯ ವಿನಂತಿಗಳು',
  'frInboxEmpty': 'ಇಲ್ಲಿ ಇನ್ನೂ ವಿನಂತಿಗಳಿಲ್ಲ.',
  'frAll': 'ಎಲ್ಲಾ',
  'frStatusNew': 'ಹೊಸದು',
  'frStatusPlanned': 'ಯೋಜನೆಯಲ್ಲಿದೆ',
  'frStatusDone': 'ಮುಗಿದಿದೆ',
  'frStatusDeclined': 'ತಿರಸ್ಕರಿಸಲಾಗಿದೆ',
  'frChange': 'ವಿನಂತಿ ನವೀಕರಿಸಿ',
  'frNoteLabel': 'ಕೇಳಿದವರಿಗೆ ಟಿಪ್ಪಣಿ (ಐಚ್ಛಿಕ)',
  'frNoteHint': 'ಉದಾ.: ಮುಂದಿನ ಅಪ್‌ಡೇಟ್‌ನಲ್ಲಿ ಬರಲಿದೆ',
  'frSaved': 'ಉಳಿಸಲಾಗಿದೆ.',
  'frFrom': 'ಕಳುಹಿಸಿದವರು',
  'frSignedOut': 'ಖಾತೆ ಅಳಿಸಲಾಗಿದೆ',
  'tabChits': 'ಚೀಟಿಗಳು',
  'tabCollect': 'ಸಂಗ್ರಹಿಸಲು',
  'tabProfile': 'ಪ್ರೊಫೈಲ್',
  'collectIntro': 'ಈ ತಿಂಗಳು ಇನ್ನೂ ಪಾವತಿಸಬೇಕಾದವರು, ನಿಮ್ಮ ಎಲ್ಲ ಚೀಟಿಗಳಲ್ಲಿ.',
  'nothingToCollect': 'ಈ ತಿಂಗಳು ಎಲ್ಲ ಚೀಟಿಗಳಲ್ಲಿ ಎಲ್ಲರೂ ಪಾವತಿಸಿದ್ದಾರೆ.',
  'secPreferences': 'ಆದ್ಯತೆಗಳು',
  'secHelp': 'ಸಹಾಯ',
  'secLegal': 'ಕಾನೂನು',
};

const Map<String, String> _hi = {
  'month1': 'जनवरी',
  'month2': 'फ़रवरी',
  'month3': 'मार्च',
  'month4': 'अप्रैल',
  'month5': 'मई',
  'month6': 'जून',
  'month7': 'जुलाई',
  'month8': 'अगस्त',
  'month9': 'सितंबर',
  'month10': 'अक्टूबर',
  'month11': 'नवंबर',
  'month12': 'दिसंबर',
  'monthShort1': 'जन',
  'monthShort2': 'फ़र',
  'monthShort3': 'मार्च',
  'monthShort4': 'अप्रै',
  'monthShort5': 'मई',
  'monthShort6': 'जून',
  'monthShort7': 'जुला',
  'monthShort8': 'अग',
  'monthShort9': 'सित',
  'monthShort10': 'अक्टू',
  'monthShort11': 'नव',
  'monthShort12': 'दिस',
  'currencyINR': 'भारतीय रुपया',
  'currencyAED': 'यूएई दिरहम',
  'currencySAR': 'सऊदी रियाल',
  'currencyQAR': 'क़तरी रियाल',
  'currencyKWD': 'कुवैती दीनार',
  'currencyOMR': 'ओमानी रियाल',
  'currencyBHD': 'बहरीनी दीनार',
  'currencyUSD': 'अमेरिकी डॉलर',
  'currencyGBP': 'ब्रिटिश पाउंड',
  'currencyEUR': 'यूरो',
  'currencySGD': 'सिंगापुर डॉलर',
  'currencyMYR': 'मलेशियाई रिंगिट',
  'currencyLKR': 'श्रीलंकाई रुपया',
  'country_in': 'भारत',
  'country_ae': 'यूएई',
  'country_sa': 'सऊदी अरब',
  'country_qa': 'क़तर',
  'country_kw': 'कुवैत',
  'country_om': 'ओमान',
  'country_bh': 'बहरीन',
  'country_us': 'अमेरिका',
  'country_gb': 'यूनाइटेड किंगडम',
  'country_au': 'ऑस्ट्रेलिया',
  'country_sg': 'सिंगापुर',
  'country_my': 'मलेशिया',
  'country_de': 'जर्मनी',
  'lang_en': 'अंग्रेज़ी',
  'lang_ar': 'अरबी',
  'lang_ml': 'मलयालम',
  'lang_ta': 'तमिल',
  'lang_kn': 'कन्नड़',
  'lang_hi': 'हिन्दी',
  'account': 'खाता',
  'askNameTitle': 'हम आपको किस नाम से बुलाएँ?',
  'importDone': 'आपकी 5K चिट आ गई है।',
  'importTitle': 'अपनी 5K चिट लाएँ',
  'importButton': 'लाएँ',
  'newChit': 'नई चिट',
  'noChits': 'अभी कोई चिट नहीं है।',
  'startChit': 'एक चिट शुरू करें',
  'yourChits': 'आपकी चिट',
  'roleAdmin': 'एडमिन',
  'monthOfTotal': 'महीना {n} / {total}, {label}',
  'ofAmount': '{amount} में से',
  'paidOfTotal': '{total} में से {paid} ने भुगतान किया',
  'collectionNote': 'वसूली {day} {month}, {note}',
  'takesPotName': 'रकम लेने वाला: {name}',
  'yourName': 'आपका नाम',
  'save': 'सेव करें',
  'cancel': 'रद्द करें',
  'close': 'बंद करें',
  'yes': 'हाँ',
  'tryAgain': 'फिर से कोशिश करें',
  'language': 'भाषा',
  'languagePhone': 'फ़ोन की भाषा',
  'agoJustNow': 'अभी',
  'agoMinutes': '{n} मिनट पहले',
  'agoToday': 'आज, {time}',
  'agoYesterday': 'कल, {time}',
  'am': 'AM',
  'pm': 'PM',
  'andJoin': '{first} और {last}',
  'slotN': 'स्लॉट {n}',
  'someone': 'कोई',
  'shareHalf': '½ हिस्सा',
  'shareThird': '⅓ हिस्सा',
  'shareQuarter': '¼ हिस्सा',
  'shareAmount': '{amount} हिस्सा',
  'noteInDays': '{n} दिन में',
  'noteTomorrow': 'कल',
  'noteToday': 'आज',
  'noteDaysLeft': 'भुगतान के लिए {n} दिन बाकी',
  'noteLastDayTomorrow': 'आख़िरी दिन कल',
  'notePayToday': 'आज आधी रात तक भुगतान करें',
  'noteDeadlinePassed': 'आख़िरी तारीख़ निकल गई',
  'errSessionEnded': 'आपका साइन इन ख़त्म हो गया है। फिर से साइन इन करें।',
  'errSignInAgain': 'फिर से साइन इन करें।',
  'errOffline': 'ऑफ़लाइन।',
  'errTimeout': 'सर्वर ने जवाब देने में बहुत समय लिया। कनेक्शन जाँचें और फिर से कोशिश करें।',
  'errNoConnection': 'कनेक्शन नहीं है। इंटरनेट जाँचें और फिर से कोशिश करें।',
  'errServer': 'Kuree सर्वर में दिक़्क़त आई। एक मिनट बाद फिर से कोशिश करें।',
  'errStatus': 'कुछ गड़बड़ हो गई ({status})।',
  'errNotOnWhatsApp': 'यह नंबर WhatsApp पर नहीं है।',
  'errCouldNotSend': 'हम कोड नहीं भेज सके। एक मिनट बाद फिर से कोशिश करें।',
  'errTooMany': 'बहुत ज़्यादा कोशिशें। एक मिनट रुककर फिर से कोशिश करें।',
  'errWrongCode': 'वह कोड ग़लत है या उसकी मियाद ख़त्म हो गई है। नया कोड माँगें।',
  'errPasswordMismatch': 'वह ईमेल और पासवर्ड मेल नहीं खाते।',
  'errPhoneCountry': 'देश कोड के साथ अपना WhatsApp नंबर डालें।',
  'errEmailLooksWrong': 'वह ईमेल सही नहीं लग रहा।',
  'errSignInNotFinished': 'साइन इन पूरा नहीं हुआ। फिर से कोशिश करें।',
  'errFile': 'अभी फ़ाइल नहीं बन सकी। एक मिनट बाद फिर से कोशिश करें।',
  'msgReminder': 'नमस्ते {name}, एक रिमाइंडर: आपकी {chit} की महीना {n} ({label}) की किस्त {amount}, {day} तारीख़ की आधी रात तक देनी है।',
  'msgReminderFrom': 'नमस्ते {name}, {group} की ओर से रिमाइंडर: आपकी {chit} की महीना {n} ({label}) की किस्त {amount}, {day} तारीख़ की आधी रात तक देनी है।',
  'msgFineAfter': ' उसके बाद {fine} देरी का जुर्माना लगेगा।',
  'msgThanks': ' धन्यवाद।',
  'msgPaidHead': '{month} : भुगतान किया',
  'msgDueHead': '{month} : अभी बाकी',
  'msgDrawResult': '{chit}, महीना {n} ({label})\nबोतल से निकला: {slot}. {name}\n{pot} की कुल रकम इन्हें मिलेगी।\nबोतल में {count} नाम थे। ड्रॉ {when}।',
  'savedMembersSee': 'सेव हो गया। सदस्य अब इसे देख सकते हैं।',
  'conflictTitle': 'किसी और ने इसे सेव किया है',
  'conflictText': 'अभी अभी किसी दूसरे एडमिन ने यह चिट सेव की। उनका बदलाव देखने के लिए रीलोड करें, फिर अपना बदलाव दोबारा करें।',
  'reload': 'रीलोड करें',
  'nobodyYet': 'अभी कोई नहीं',
  'clearChoice': 'चुनाव हटाएँ',
  'takesPotInMonth': 'महीना {n} में रकम लेने वाला',
  'allSlotsTaken': 'सभी स्लॉट पहले ही रकम ले चुके हैं।',
  'onlyOneLeft': 'सिर्फ़ {name} बचे हैं, इसलिए ड्रॉ की ज़रूरत नहीं। चुनें का इस्तेमाल करें।',
  'savedMonthGoesTo': 'सेव हो गया। महीना {n} की रकम {name} को।',
  'drawDonePressSave': 'ड्रॉ हो गया। प्रकाशित करने के लिए सेव दबाएँ।',
  'numberAddedPressSave': 'नंबर जुड़ गया। रखने के लिए सेव दबाएँ।',
  'slotsFromNames': 'नीचे नाम जोड़ें। हर नाम एक स्लॉट है, और हर स्लॉट के लिए एक महीना।',
  'fineChip': 'देरी का जुर्माना {fine}',
  'fineEach': 'हर देर से भुगतान पर {fine}',
  'addLateFine': 'देरी का जुर्माना जोड़ें',
  'fineSheetText': 'हर देर से भुगतान पर उस महीने की रकम में जुड़ता है। पहले से लगे जुर्माने अपनी रकम पर ही रहेंगे।',
  'fineChangedPressSave': 'देरी का जुर्माना अब {fine} है। रखने के लिए सेव दबाएँ।',
  'fineOffPressSave': 'अब से देरी का जुर्माना नहीं। रखने के लिए सेव दबाएँ।',
  'newLinkTitle': 'नया लिंक बनाएँ?',
  'newLinkText': 'पुराना लिंक तुरंत काम करना बंद कर देगा। नया लिंक ग्रुप में शेयर करें।',
  'newLinkYes': 'नया लिंक बनाएँ',
  'makingSheet': 'स्प्रेडशीट बन रही है…',
  'saveFirstTitle': 'पहले सेव करें?',
  'saveFirstText': 'चिट बदलने से पहले इस महीने के बदलाव सेव करें।',
  'deleteChitTitle': '{name} हटाएँ?',
  'deleteChitText': 'चिट, उसका इतिहास और सदस्यों का लिंक हमेशा के लिए हट जाएँगे। यह वापस नहीं हो सकता।',
  'delete': 'हटाएँ',
  'membersLink': 'सदस्यों का लिंक',
  'membersLinkSub': 'इसे ग्रुप में शेयर करें',
  'drawRest': 'बाकी का ड्रॉ करें',
  'drawRestSub': 'बचे हुए सभी महीनों को फेंटें',
  'spreadsheet': 'स्प्रेडशीट',
  'spreadsheetSub': 'हर महीना, हर सदस्य',
  'history': 'इतिहास',
  'historySub': 'पहले के सभी संस्करण',
  'admins': 'एडमिन',
  'adminsSub': 'यह चिट कौन चलाता है',
  'editChit': 'चिट बदलें',
  'editChitSub': 'नाम, रकम, मुद्रा, तारीख़ें, स्लॉट, लोग',
  'deleteChit': 'चिट हटाएँ',
  'leaveTitle': 'बिना सेव किए जाएँ?',
  'leaveText': 'इस महीने के आपके बदलाव अभी सेव नहीं हुए हैं।',
  'leave': 'जाएँ',
  'more': 'और',
  'saveChangesFirst': 'पहले अपने बदलाव सेव करें।',
  'historyKept': 'हर सेव इतिहास में रखा जाता है, कुछ भी नहीं खोता।',
  'lastSavedBy': 'आख़िरी बार सेव किया {name} ने, {when}',
  'notSavedYet': 'अभी सेव नहीं हुआ',
  'undo': 'पहले जैसा करें',
  'prevMonth': 'पिछला महीना',
  'nextMonth': 'अगला महीना',
  'prevYear': 'पिछला साल',
  'nextYear': 'अगला साल',
  'monthNLabel': 'महीना {n}, {label}',
  'collectedOf': '{pot} में से जमा',
  'collectedOfFines': '{pot} में से जमा, साथ में {fines} जुर्माना',
  'toGo': '{n} बाकी',
  'everyonePaid': 'सबने भुगतान किया',
  'heroCollection': 'वसूली {day} {month}, {payDay} {payMonth} तक भुगतान करें: {note}',
  'month': 'महीना',
  'settled': 'पूरा हुआ',
  'inProgress': 'चल रहा है',
  'inProgressTakes': 'चल रहा है, रकम {name} को',
  'upcoming': 'आने वाला',
  'upcomingTakes': 'आने वाला, रकम {name} को',
  'winnerAmountFine': '{total} (कुल रकम और {fine} जुर्माना)',
  'pickedFromBottle': '{amount}, बोतल से निकला',
  'takesPotThisMonth': 'इस महीने रकम लेने वाला',
  'notDecided': 'अभी तय नहीं',
  'bottleDraw': 'बोतल ड्रॉ',
  'choose': 'चुनें',
  'change': 'बदलें',
  'allPaid': 'सबने भुगतान किया',
  'reminders': 'रिमाइंडर',
  'everyonePaidFor': 'महीना {n} के लिए सबने भुगतान किया',
  'showList': 'दिखाएँ',
  'hideList': 'छिपाएँ',
  'filterAll': 'सभी {n}',
  'filterDue': 'बाकी {n}',
  'filterPaid': 'भुगतान {n}',
  'tickHelp': 'जब कोई भुगतान करे तो टिक दबाएँ। अगर आख़िरी तारीख़ के बाद भुगतान किया हो तो देरी दबाएँ।',
  'everyonePaidMonth': 'महीना {n} के लिए सबने भुगतान कर दिया है।',
  'nobodyPaidMonth': 'महीना {n} के लिए अभी किसी ने भुगतान नहीं किया।',
  'statusPaid': 'भुगतान {amount}',
  'statusPending': 'बाकी {amount}',
  'statusLateFine': '{status}, देरी का जुर्माना {fine}',
  'monthN': 'महीना {n}',
  'semPaid': 'भुगतान किया: {name}',
  'semLate': 'देरी का जुर्माना, {name}',
  'lateButton': 'देरी',
  'couldNotOpen': 'उसे खोल नहीं सके। क्या WhatsApp इंस्टॉल है?',
  'copied': 'कॉपी हो गया',
  'drawTitle': 'महीना {n} का ड्रॉ',
  'drawSubtitle': '{label}, कुल रकम {pot}',
  'savedToPhotos': 'आपकी फ़ोटो में सेव हो गया।',
  'videoFailed': 'इस फ़ोन पर वीडियो नहीं बन सका।',
  'drawShareTitle': '{title}, महीना {n} का ड्रॉ',
  'stopDrawTitle': 'ड्रॉ रोकें?',
  'nothingSaved': 'कुछ भी सेव नहीं होगा।',
  'stop': 'रोकें',
  'closeUnsavedTitle': 'बिना सेव किए बंद करें?',
  'winnerNotSaved': 'रकम लेने वाला अभी सेव नहीं हुआ है।',
  'slipsGoIn': '{n} पर्चियाँ बोतल में जाएँगी, हर उस स्लॉट के लिए एक जो अभी रकम का इंतज़ार कर रहा है।',
  'recordHint': 'इस स्क्रीन के ऊपर दूसरा फ़ोन पकड़कर रिकॉर्डिंग शुरू करें, फिर ड्रॉ शुरू करें दबाएँ। गिनती 3 से शुरू होगी।',
  'musicSound': 'संगीत और आवाज़ें',
  'gettingReady': 'तैयारी हो रही है',
  'startDraw': 'ड्रॉ शुरू करें',
  'takesPotFor': 'महीना {n}, {label}: रकम इन्हें मिलेगी।',
  'saved': 'सेव हो गया',
  'saveAsWinner': 'महीना {n} का रकम लेने वाला सेव करें',
  'makingVideo': 'वीडियो बन रहा है {pct}%',
  'shareVideo': 'वीडियो शेयर करें',
  'saveVideo': 'वीडियो सेव करें',
  'sendResultWa': 'नतीजा WhatsApp पर भेजें',
  'drawGetReady': 'तैयार हो जाइए',
  'drawStartsSoon': 'ड्रॉ बस शुरू होने वाला है',
  'drawWriting': 'हर नाम लिखा जा रहा है',
  'drawWritingSub': 'रकम का इंतज़ार कर रहे हर स्लॉट के लिए एक पर्ची',
  'drawInto': 'बोतल में',
  'drawClosing': 'बोतल बंद हो रही है',
  'drawShaking': 'हिलाया जा रहा है',
  'drawShakingSub': 'हर पर्ची का बराबर मौका',
  'drawPicking': 'एक पर्ची निकल रही है',
  'drawFooterDrawn': 'बोतल में {n} नाम। ड्रॉ {when}',
  'drawFooterNow': 'बोतल में {n} नाम। {when}',
  'everyMonthTaken': 'अगले महीने से हर महीने के लिए रकम लेने वाला पहले से तय है।',
  'drawRestIntro': '{slots} स्लॉट अभी रकम लेने बाकी हैं, {from} से {months} महीनों में। हर स्लॉट का एक ड्रॉ।',
  'drawRestIntroOne': '{slots} स्लॉट अभी रकम लेने बाकी हैं, {from} से 1 महीने में। हर स्लॉट का एक ड्रॉ।',
  'noSlotLeft': 'कोई स्लॉट नहीं बचा',
  'notPlaced': 'जगह नहीं मिली (महीने नहीं बचे): {list}',
  'useThisOrder': 'यह क्रम इस्तेमाल करें',
  'useOrderTitle': 'यह क्रम इस्तेमाल करें?',
  'useOrderText': 'इससे {n} महीनों के लिए रकम लेने वाले तय होंगे। सेव करने से पहले आप किसी भी महीने को हाथ से बदल सकते हैं।',
  'useIt': 'इस्तेमाल करें',
  'shuffleAgain': 'फिर से फेंटें',
  'remindersTitle': 'रिमाइंडर, महीना {n}',
  'shareListInGroup': 'सूची ग्रुप में शेयर करें',
  'nobodyToRemind': 'सबने भुगतान कर दिया है, याद दिलाने को कोई नहीं।',
  'remindEach': 'या हर व्यक्ति को अलग से मैसेज करें। {rest}',
  'everyoneHasNumber': 'यहाँ सबका नंबर है।',
  'noNumberOne': '1 व्यक्ति का नंबर अभी नहीं है।',
  'noNumberMany': '{n} लोगों का नंबर अभी नहीं है।',
  'noNumberYet': 'अभी नंबर नहीं है',
  'dueMonth': '{amount} बाकी, महीना {n}',
  'addNumber': 'नंबर जोड़ें',
  'sent': 'भेजा गया',
  'remind': 'याद दिलाएँ',
  'couldNotOpenWa': 'WhatsApp नहीं खुल सका।',
  'numberTitle': '{name} का नंबर',
  'enterWaNumber': 'WhatsApp नंबर डालें।',
  'waNumberHint': 'WhatsApp नंबर',
  'numberUse': 'सिर्फ़ रिमाइंडर के लिए। सदस्य इसे कभी नहीं देखते।',
  'saveNumber': 'नंबर सेव करें',
  'linkExplain': 'सदस्य इसे किसी भी ब्राउज़र में खोल सकते हैं। वे देखते हैं कि किसने भुगतान किया, जुर्माने, रकम किसने ली और आगे क्या है। न ऐप चाहिए न साइन इन, और कोई फ़ोन नंबर नहीं दिखता।',
  'copy': 'कॉपी करें',
  'linkCopied': 'लिंक कॉपी हो गया',
  'whatsapp': 'WhatsApp',
  'open': 'खोलें',
  'share': 'शेयर करें',
  'errNeedName': 'चिट को एक नाम दें, जैसे 5K चिट।',
  'errNeedShare': 'हर स्लॉट महीने में कितना देता है, यह डालें।',
  'errSlotName': 'स्लॉट {n} के लिए एक नाम चाहिए।',
  'errPartsSum': 'स्लॉट {n}: हिस्सों का जोड़ {total} है, पर एक स्लॉट {share} देता है।',
  'errPartAmount': 'स्लॉट {n}: हर व्यक्ति कितना देता है, यह डालें।',
  'errFewerSlots': 'महीना {n} में पहले से भुगतान या रकम लेने वाला है, इसलिए चिट में {n} से कम स्लॉट नहीं हो सकते।',
  'errTakerSlot': 'स्लॉट {slot} ने महीना {n} में रकम ली है, इसलिए चिट में कम से कम {slot} स्लॉट चाहिए।',
  'errConflictEditor': 'अभी अभी किसी दूसरे एडमिन ने यह चिट सेव की। वापस जाएँ, रीलोड करें, फिर अपने बदलाव दोबारा करें।',
  'firstMonth': 'पहला महीना',
  'shorterMonths': 'छोटे महीनों में आख़िरी दिन',
  'currency': 'मुद्रा',
  'sectionChit': 'चिट',
  'sectionMoney': 'पैसा',
  'sectionDates': 'तारीख़ें',
  'fieldName': 'नाम',
  'nameHint': '5K चिट',
  'fieldGroup': 'ग्रुप',
  'groupHint': 'रिवरसाइड',
  'eachSlotPays': 'हर स्लॉट महीने में देता है',
  'lateFine': 'देरी का जुर्माना',
  'fineNone': 'कोई नहीं',
  'slots': 'स्लॉट',
  'fewerSlots': 'स्लॉट घटाएँ',
  'moreSlots': 'स्लॉट बढ़ाएँ',
  'potSummary': 'हर महीने {pot} कुल रकम, {n} महीनों तक',
  'potSummaryNone': 'हर महीने एक स्लॉट रकम लेता है, {n} महीनों तक',
  'collectionDay': 'वसूली का दिन',
  'everyMonthDay': 'हर महीने की {day} तारीख़',
  'lastDayToPay': 'भुगतान का आख़िरी दिन',
  'byMidnight': '{day} तारीख़, आधी रात तक',
  'byMidnightNext': 'अगले महीने की {day} तारीख़, आधी रात तक',
  'oneNamePerSlot': 'हर स्लॉट में एक नाम',
  'numbersForReminders': 'रिमाइंडर के लिए नंबर',
  'countOf': '{a} / {b}',
  'addNamesFirst': 'पहले स्लॉट में नाम जोड़ें।',
  'numbersNote': 'नंबर सिर्फ़ WhatsApp रिमाइंडर के लिए हैं। सदस्यों के लिंक पर ये कभी नहीं दिखते।',
  'startTheChit': 'चिट शुरू करें',
  'saveChanges': 'बदलाव सेव करें',
  'nameN': 'नाम {n}',
  'remove': 'हटाएँ',
  'splitSlot': 'यह स्लॉट बाँटें',
  'addPerson': 'एक व्यक्ति जोड़ें',
  'somethingWrong': 'कुछ गड़बड़ हो गई। फिर से कोशिश करें।',
  'enterYourWa': 'अपना WhatsApp नंबर डालें।',
  'enterCode': '6 अंकों का कोड डालें।',
  'enterEmailPassword': 'ईमेल और पासवर्ड डालें।',
  'subPhoneCode': 'कोड के लिए WhatsApp देखें।',
  'subEmailCode': 'कोड के लिए अपना ईमेल देखें।',
  'subPhone': 'अपने WhatsApp नंबर से साइन इन करें।',
  'subEmail': 'अपने ईमेल से साइन इन करें।',
  'subStart': 'अपनी चिट अपने फ़ोन से चलाएँ।',
  'privacy': 'प्राइवेसी',
  'terms': 'शर्तें',
  'continueWa': 'WhatsApp से जारी रखें',
  'useEmailInstead': 'इसकी जगह ईमेल इस्तेमाल करें',
  'phoneHint': 'फ़ोन नंबर',
  'sendCodeWa': 'WhatsApp पर कोड भेजें',
  'codeSentWa': 'हमने {to} पर WhatsApp में 6 अंकों का कोड भेजा है। यह 10 मिनट तक चलेगा।',
  'codeSentEmail': 'हमने {to} पर 6 अंकों का कोड भेजा है। यह 10 मिनट तक चलेगा।',
  'signIn': 'साइन इन करें',
  'sendAgainIn': '{n} सेकंड में फिर से भेजें',
  'sendAgain': 'फिर से भेजें',
  'anotherNumber': 'दूसरा नंबर',
  'anotherEmail': 'दूसरा ईमेल',
  'email': 'ईमेल',
  'emailMeCode': 'मुझे ईमेल पर कोड भेजें',
  'useWa': 'WhatsApp इस्तेमाल करें',
  'usePassword': 'पासवर्ड इस्तेमाल करें',
  'password': 'पासवर्ड',
  'emailCodeInstead': 'इसकी जगह ईमेल पर कोड भेजें',
  'countryCode': 'देश कोड',
  'signOutTitle': 'साइन आउट करें?',
  'signOutText': 'आपकी चिट सर्वर पर सुरक्षित रहेंगी। उन्हें देखने के लिए फिर से साइन इन करें।',
  'signOut': 'साइन आउट',
  'deleteAccountTitle': 'अपना खाता हटाएँ?',
  'deleteAccountText': 'आपका Kuree खाता और नाम हट जाएँगे। जिन चिट के आप मालिक हैं, वे अगले एडमिन को चली जाएँगी। जो चिट सिर्फ़ आप चलाते हैं, वे अपने इतिहास और सदस्यों के लिंक के साथ हमेशा के लिए हट जाएँगी। यह वापस नहीं हो सकता।',
  'deleteLoginToo': 'मेरा SkiFi लॉगिन भी हटाएँ',
  'deleteLoginTooSub': 'जिस नंबर या ईमेल से आप साइन इन करते हैं। उसे इस्तेमाल करने वाले दूसरे SkiFi ऐप में भी वह नहीं रहेगा।',
  'deleteAccount': 'खाता हटाएँ',
  'deleting': 'हटाया जा रहा है…',
  'noNameYet': 'अभी कोई नाम नहीं',
  'edit': 'बदलें',
  'requestFeature': 'कोई फ़ीचर माँगें',
  'featureInbox': 'फ़ीचर अनुरोध',
  'contact': 'संपर्क',
  'histPaid': 'महीना {n}: {a} ने भुगतान किया था, बाद में {b}',
  'histNoTaker': 'महीना {n} में तब रकम लेने वाला तय नहीं था',
  'histWentTo': 'महीना {n} की रकम {name} को गई थी',
  'histFines': 'महीना {n}: {count} देरी के जुर्माने',
  'histSettings': 'अलग सेटिंग',
  'histPeople': 'अलग लोग या स्लॉट',
  'histSmall': 'छोटे बदलाव',
  'histAndMore': 'और भी',
  'restoreTitle': 'यह संस्करण वापस लाएँ?',
  'restoreText': 'चिट वैसी हो जाएगी जैसी {name} ने {when} छोड़ी थी। अभी जो दिख रहा है वह भी इतिहास में रहेगा, इसलिए आप इसे पलट सकते हैं।',
  'putItBack': 'वापस लाएँ',
  'historyEmpty': 'अभी पहले के संस्करण नहीं हैं। हर सेव एक जोड़ता है।',
  'savedBy': '{name} ने सेव किया',
  'putBack': 'वापस लाएँ',
  'addAnAdmin': 'एक एडमिन जोड़ें',
  'adminAdded': 'जुड़ गए। साइन इन करने पर वे यह चिट देखेंगे।',
  'leaveChitTitle': 'यह चिट छोड़ें?',
  'removeAdminTitle': '{name} को हटाएँ?',
  'leaveChitText': 'फिर आप इसे न देख पाएँगे न बदल पाएँगे।',
  'removeAdminText': 'फिर वे यह चिट न देख पाएँगे न बदल पाएँगे।',
  'makeOwnerTitle': '{name} को मालिक बनाएँ?',
  'makeOwnerText': 'वे एडमिन जोड़ और हटा सकेंगे और चिट हटा सकेंगे। आप एडमिन बने रहेंगे।',
  'makeOwner': 'मालिक बनाएँ',
  'ownsNow': 'अब चिट के मालिक {name} हैं।',
  'addAdmin': 'एडमिन जोड़ें',
  'adminsExplain': 'एडमिन भुगतान दर्ज करते हैं, ड्रॉ करते हैं और रिमाइंडर भेजते हैं। मालिक एडमिन जोड़ता और हटाता भी है।',
  'roleOwner': 'मालिक',
  'you': 'आप',
  'leaveChit': 'यह चिट छोड़ें',
  'removeAdmin': 'एडमिन हटाएँ',
  'enterTheirWa': 'उनका WhatsApp नंबर डालें।',
  'enterTheirEmail': 'उनका ईमेल डालें।',
  'theirName': 'उनका नाम',
  'useEmail': 'ईमेल इस्तेमाल करें',
  'adminSignInEmail': 'चिट देखने के लिए वे इसी ईमेल से Kuree में साइन इन करेंगे।',
  'adminSignInNumber': 'चिट देखने के लिए वे इसी नंबर से Kuree में साइन इन करेंगे।',
  'frTitle': 'कोई फ़ीचर माँगें',
  'frIntroTitle': 'बताइए क्या मदद करेगा',
  'frIntroText': 'कोई सुझाव, कोई अड़चन, कोई फ़ीचर जिसकी कमी लगती हो। हम हर अनुरोध पढ़ते हैं।',
  'frFieldTitle': 'कुछ शब्दों में आपका सुझाव',
  'frFieldTitleHint': 'जैसे: एक दिन पहले रिमाइंडर',
  'frFieldDetails': 'थोड़ा और बताइए (वैकल्पिक)',
  'frFieldDetailsHint': 'आप इसे कैसे इस्तेमाल करेंगे? आज क्या होता है?',
  'frImportance': 'इससे कितनी मदद होगी?',
  'frNice': 'हो तो अच्छा',
  'frImportant': 'ज़रूरी',
  'frMust': 'बहुत ज़रूरी',
  'frSend': 'अनुरोध भेजें',
  'frNeedTitle': 'अपने सुझाव को एक छोटा शीर्षक दें।',
  'frThanksTitle': 'धन्यवाद!',
  'frThanksText': 'आपका अनुरोध Kuree टीम तक पहुँच गया है। आप नीचे उसे देखते रह सकते हैं।',
  'frSendAnother': 'एक और भेजें',
  'frYours': 'आपके अनुरोध',
  'frNoneYet': 'आपके अनुरोध और टीम का फ़ैसला यहाँ दिखेंगे।',
  'frReply': 'Kuree टीम की ओर से',
  'frInboxTitle': 'फ़ीचर अनुरोध',
  'frInboxEmpty': 'यहाँ अभी कोई अनुरोध नहीं है।',
  'frAll': 'सभी',
  'frStatusNew': 'नया',
  'frStatusPlanned': 'योजना में',
  'frStatusDone': 'हो गया',
  'frStatusDeclined': 'अस्वीकार',
  'frChange': 'अनुरोध अपडेट करें',
  'frNoteLabel': 'पूछने वाले के लिए नोट (वैकल्पिक)',
  'frNoteHint': 'जैसे: अगले अपडेट में आएगा',
  'frSaved': 'सेव हो गया।',
  'frFrom': 'भेजने वाले',
  'frSignedOut': 'खाता हटा दिया गया',
  'tabChits': 'चिट',
  'tabCollect': 'वसूली बाकी',
  'tabProfile': 'प्रोफ़ाइल',
  'collectIntro': 'इस महीने अभी भुगतान बाकी, आपके सभी चिट में।',
  'nothingToCollect': 'इस महीने हर चिट में सबने भुगतान कर दिया है।',
  'secPreferences': 'पसंद',
  'secHelp': 'मदद',
  'secLegal': 'कानूनी',
};

const Map<String, Map<String, String>> _tables = {'en': _en, 'ar': _ar, 'ml': _ml, 'ta': _ta, 'kn': _kn, 'hi': _hi};
