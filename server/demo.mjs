/* The demo kuri behind kureeapp.com/k/demo: a made-up group, so the
   landing page can show the real members' page without anyone's real names.
   It is built fresh around today, so month 5 is always the current month:
   months 1 to 4 are paid and drawn, month 5 is part paid and waiting for
   its draw. */

const NAMES = ['Rahul', 'Fathima', 'Jibin', 'Shabna', 'Vishnu', 'Ann Mary', 'Salman', 'Meera', 'Anand', 'Riya', 'Jaseem', 'Aswathy', 'Faisal'];
const SLOT = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 11, 12];
const SHARE = 10000;
const WINNERS = [6, 2, 11, 8];
const UNPAID_NOW = new Set(['s5', 's9', 's11', 's13']);

export function demoKuri(now = new Date()) {
  const start = new Date(now.getFullYear(), now.getMonth() - 4, 1);
  const people = NAMES.map((name, i) => ({ id: `p${i + 1}`, name }));
  const payers = people.map((p, i) => ({ id: `s${i + 1}`, slot: SLOT[i], person: p.id, amt: SLOT[i] === 10 ? SHARE / 2 : SHARE }));
  const months = [];
  for (let n = 1; n <= 12; n++) {
    const m = { n, winner: null, paid: {}, fines: {}, note: '' };
    if (n <= 4) {
      for (const p of payers) m.paid[p.id] = true;
      const won = WINNERS[n - 1];
      const at = new Date(start.getFullYear(), start.getMonth() + n - 1, 1, 19, 30);
      m.winner = won;
      m.draw = { how: 'bottle', at: at.toISOString(), by: 'Rahul', picked: won, names: SLOT.filter((s, i) => SLOT.indexOf(s) === i && !WINNERS.slice(0, n - 1).includes(s)) };
    }
    if (n === 2) m.fines.s7 = true;
    if (n === 4) m.fines.s3 = true;
    if (n === 5) {
      for (const p of payers) if (!UNPAID_NOW.has(p.id)) m.paid[p.id] = true;
      if (now.getDate() > 10) m.fines.s8 = true;
    }
    months.push(m);
  }
  const data = {
    v: 1,
    name: '10K Kuri',
    group: 'Riverside',
    share: SHARE,
    slots: 12,
    startYear: start.getFullYear(),
    startMonth: start.getMonth() + 1,
    collectDay: 1,
    lastDay: 10,
    fine: 200,
    people,
    payers,
    months,
    updated: '',
  };
  // One stamp per day, so the spreadsheet is made once a day.
  const day = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 9, 30);
  return { data, updated_at: day.toISOString() };
}
