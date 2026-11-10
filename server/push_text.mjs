/*
 * The words of Kuree's push notifications, in the app's six languages. The
 * title is the chit's name; the body is one of these. Same rules as the app:
 * "chit", never "kuri"; no em dashes, no middle dots.
 *
 * {by} who made the change, {who} the person (or a slot's people),
 * {n} how many payments, {m} the month, {slot} the slot number. A draw in
 * a month with several takers has their names in args.whos, joined with
 * the language's "and".
 */
export const TEXT = {
  en: {
    paid_one: '{by} marked {who} paid',
    paid_many: '{by} marked {n} payments paid',
    unpaid_one: '{by} marked {who} not paid',
    unpaid_many: '{by} marked {n} payments not paid',
    late_one: '{by} marked {who} late',
    late_many: '{by} marked {n} payments late',
    draw: 'Month {m}: {who} takes the pot',
    draw_many: 'Month {m}: {who} take the pot',
    draw_slot: 'Month {m}: slot {slot} takes the pot',
    admin_added: '{by} added you as an admin',
    and: '{first} and {last}',
  },
  ar: {
    paid_one: 'سجّل {by} أن {who} دفع',
    paid_many: 'سجّل {by} {n} دفعات',
    unpaid_one: 'سجّل {by} أن {who} لم يدفع',
    unpaid_many: 'سجّل {by} {n} دفعات غير مدفوعة',
    late_one: 'سجّل {by} أن {who} متأخر',
    late_many: 'سجّل {by} {n} دفعات متأخرة',
    draw: 'الشهر {m}: يستلم الجمعية {who}',
    draw_many: 'الشهر {m}: يستلم الجمعية {who}',
    draw_slot: 'الشهر {m}: يستلم الجمعية السهم {slot}',
    admin_added: 'أضافك {by} مشرفًا',
    and: '{first} و{last}',
  },
  ml: {
    paid_one: '{who} അടച്ചതായി {by} രേഖപ്പെടുത്തി',
    paid_many: '{n} അടവുകൾ അടച്ചതായി {by} രേഖപ്പെടുത്തി',
    unpaid_one: '{who} അടച്ചിട്ടില്ലെന്ന് {by} രേഖപ്പെടുത്തി',
    unpaid_many: '{n} അടവുകൾ അടച്ചിട്ടില്ലെന്ന് {by} രേഖപ്പെടുത്തി',
    late_one: '{who} വൈകിയെന്ന് {by} രേഖപ്പെടുത്തി',
    late_many: '{n} അടവുകൾ വൈകിയെന്ന് {by} രേഖപ്പെടുത്തി',
    draw: 'മാസം {m}: കുറി കിട്ടുന്നത് {who}',
    draw_many: 'മാസം {m}: കുറി കിട്ടുന്നത് {who}',
    draw_slot: 'മാസം {m}: കുറി കിട്ടുന്നത് സ്ലോട്ട് {slot}',
    admin_added: '{by} നിങ്ങളെ അഡ്മിനായി ചേർത്തു',
    and: '{first}, {last}',
  },
  ta: {
    paid_one: '{who} செலுத்தியதாக {by} குறித்தார்',
    paid_many: '{n} கட்டணங்கள் செலுத்தப்பட்டதாக {by} குறித்தார்',
    unpaid_one: '{who} செலுத்தவில்லை என {by} குறித்தார்',
    unpaid_many: '{n} கட்டணங்கள் செலுத்தப்படவில்லை என {by} குறித்தார்',
    late_one: '{who} தாமதம் என {by} குறித்தார்',
    late_many: '{n} கட்டணங்கள் தாமதம் என {by} குறித்தார்',
    draw: 'மாதம் {m}: சீட்டு எடுப்பவர் {who}',
    draw_many: 'மாதம் {m}: சீட்டு எடுப்பவர்கள் {who}',
    draw_slot: 'மாதம் {m}: சீட்டு எடுப்பவர் ஸ்லாட் {slot}',
    admin_added: '{by} உங்களை நிர்வாகியாகச் சேர்த்தார்',
    and: '{first} மற்றும் {last}',
  },
  kn: {
    paid_one: '{who} ಪಾವತಿಸಿದ್ದಾರೆ ಎಂದು {by} ಗುರುತಿಸಿದರು',
    paid_many: '{n} ಪಾವತಿಗಳನ್ನು {by} ಗುರುತಿಸಿದರು',
    unpaid_one: '{who} ಪಾವತಿಸಿಲ್ಲ ಎಂದು {by} ಗುರುತಿಸಿದರು',
    unpaid_many: '{n} ಪಾವತಿಗಳು ಬಾಕಿ ಎಂದು {by} ಗುರುತಿಸಿದರು',
    late_one: '{who} ತಡ ಎಂದು {by} ಗುರುತಿಸಿದರು',
    late_many: '{n} ಪಾವತಿಗಳು ತಡ ಎಂದು {by} ಗುರುತಿಸಿದರು',
    draw: 'ತಿಂಗಳು {m}: ಚೀಟಿ ಪಡೆಯುವವರು {who}',
    draw_many: 'ತಿಂಗಳು {m}: ಚೀಟಿ ಪಡೆಯುವವರು {who}',
    draw_slot: 'ತಿಂಗಳು {m}: ಚೀಟಿ ಪಡೆಯುವವರು ಸ್ಲಾಟ್ {slot}',
    admin_added: '{by} ನಿಮ್ಮನ್ನು ನಿರ್ವಾಹಕರಾಗಿ ಸೇರಿಸಿದರು',
    and: '{first} ಮತ್ತು {last}',
  },
  hi: {
    paid_one: '{by} ने {who} का भुगतान दर्ज किया',
    paid_many: '{by} ने {n} भुगतान दर्ज किए',
    unpaid_one: '{by} ने {who} का भुगतान बाकी दर्ज किया',
    unpaid_many: '{by} ने {n} भुगतान बाकी दर्ज किए',
    late_one: '{by} ने {who} को देरी में दर्ज किया',
    late_many: '{by} ने {n} भुगतान देरी में दर्ज किए',
    draw: 'महीना {m}: रकम लेने वाला {who}',
    draw_many: 'महीना {m}: रकम लेने वाले {who}',
    draw_slot: 'महीना {m}: रकम लेने वाला स्लॉट {slot}',
    admin_added: '{by} ने आपको एडमिन बनाया',
    and: '{first} और {last}',
  },
};

/** The title and body for one outbox line, in one language. */
export function words(kind, args, lang) {
  const t = TEXT[lang] || TEXT.en;
  let key;
  const whos = Array.isArray(args.whos) ? args.whos.map((x) => String(x || '').trim()).filter(Boolean) : [];
  if (kind === 'draw' && whos.length > 1) {
    const and = t.and || TEXT.en.and;
    args = { ...args, who: and.replace('{first}', whos.slice(0, -1).join(', ')).replace('{last}', whos[whos.length - 1]) };
    key = 'draw_many';
  } else if (kind === 'draw') key = args.who ? 'draw' : 'draw_slot';
  else if (kind === 'admin_added') key = 'admin_added';
  else key = `${kind}_${args.who && Number(args.n) === 1 ? 'one' : 'many'}`;
  const template = t[key] || TEXT.en[key];
  if (!template) return null;
  const by = String(args.by || '').trim() || 'Kuree';
  const body = template.replace(/\{(\w+)\}/g, (_, k) => String(k === 'by' ? by : args[k] ?? ''));
  return { title: String(args.chit || 'Kuree'), body };
}
