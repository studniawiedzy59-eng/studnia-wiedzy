import json, pathlib
OUT = pathlib.Path('/home/claude/studnia-wiedzy/assets/content/en/lessons')
uk = lambda s: {"uk": s}
def W(text, ipa, pos, tr, ex, extr):
    return {"id": text.lower().replace(" ", "_").replace("'", ""), "text": text, "ipa": ipa, "pos": pos,
            "translation": uk(tr), "example": ex, "exampleTranslation": uk(extr)}
def mc(p, opts, e): return {"type": "multiple_choice", "prompt": uk(p), "options": opts, "answer": 0, "explanation": uk(e)}
def mcu(p, opts, e): return {"type": "multiple_choice", "prompt": uk(p), "options": uk(opts), "answer": 0, "explanation": uk(e)}
def li(a, p, opts, e): return {"type": "listening", "audioText": a, "prompt": uk(p), "options": opts, "answer": 0, "explanation": uk(e)}
def liu(a, p, opts, e): return {"type": "listening", "audioText": a, "prompt": uk(p), "options": uk(opts), "answer": 0, "explanation": uk(e)}
def fb(s, opts, e, p="Оберіть слово, якого бракує"): return {"type": "fill_blank", "prompt": uk(p), "sentence": s, "options": opts, "answer": 0, "explanation": uk(e)}
def mt(pairs, e, p="З'єднайте слова з перекладом"): return {"type": "matching", "prompt": uk(p), "pairs": [{"left": l, "right": uk(r)} for l, r in pairs], "explanation": uk(e)}
def bs(p, ans, extra, e): return {"type": "build_sentence", "prompt": uk(p), "words": ans + extra, "answer": ans, "explanation": uk(e)}
def tr(p, answers, e): return {"type": "translate", "prompt": uk(p), "answers": answers, "explanation": uk(e)}
def lesson(n, title, goal, rule, words, exs, review=False):
    for i, e in enumerate(exs, 1): e["id"] = f"e{i}"
    exs = [dict(id=e.pop("id"), **e) for e in exs]
    d = {"id": f"u02_l0{n}", "unit": "u02", "cefr": "A0"}
    if review: d["review"] = True
    d.update(title=uk(title), goal=uk(goal), rule=uk(rule), words=words, exercises=exs)
    (OUT / f"u02_l0{n}.json").write_text(json.dumps(d, ensure_ascii=False, indent=1) + "\n")

lesson(1, "Кава чи чай?", "Назвати напої й попросити один із них.",
 "Щоб замовити, достатньо назвати напій і додати please: A coffee, please. Маленьке слово a означає «один, одна». With — «з»: tea with milk — чай із молоком.",
 [W("coffee", "/ˈkɒfi/", "noun", "кава", "A coffee, please.", "Каву, будь ласка."),
  W("tea", "/tiː/", "noun", "чай", "A tea, please.", "Чай, будь ласка."),
  W("water", "/ˈwɔːtə/", "noun", "вода", "Water, please.", "Води, будь ласка."),
  W("juice", "/dʒuːs/", "noun", "сік", "A juice, please.", "Сік, будь ласка."),
  W("milk", "/mɪlk/", "noun", "молоко", "Tea with milk, please.", "Чай із молоком, будь ласка."),
  W("sugar", "/ˈʃʊɡə/", "noun", "цукор", "Coffee with sugar.", "Кава з цукром."),
  W("with", "/wɪð/", "preposition", "з, із", "Tea with milk.", "Чай із молоком."),
  W("a", "/ə/", "determiner", "один, одна (перед назвою речі)", "A coffee, please.", "Каву, будь ласка.")],
 [mc("Повторимо. Як сказати «два»?", ["two", "three", "ten"], "Two — два. Three — три, ten — десять."),
  mt([("coffee", "кава"), ("tea", "чай"), ("water", "вода"), ("juice", "сік")], "Coffee, tea, water, juice — чотири напої, які є в кожному кафе."),
  liu("A coffee, please.", "Прослухайте. Що просить людина?", ["Каву", "Чай", "Воду"], "A coffee, please — «каву, будь ласка»."),
  mt([("milk", "молоко"), ("sugar", "цукор"), ("with", "з, із"), ("please", "будь ласка")], "With milk — з молоком, with sugar — з цукром."),
  fb("Tea ___ milk, please.", ["with", "and", "from"], "«З молоком» — with milk. From означає «з», коли кажуть, звідки хтось родом."),
  fb("___ coffee, please.", ["A", "I", "My"], "Перед назвою однієї речі ставлять a: a coffee, a tea."),
  bs("Каву, будь ласка.", ["A", "coffee", "please"], ["tea", "with"], "Спочатку a coffee, наприкінці please."),
  liu("Tea with sugar, please.", "Прослухайте. Що просить людина?", ["Чай із цукром", "Чай із молоком", "Каву з цукром"], "Tea — чай, with sugar — з цукром."),
  tr("Чай із молоком, будь ласка.", ["Tea with milk, please", "A tea with milk, please"], "Tea with milk, please. With — «з»."),
  li("Coffee or tea?", "Вас питають: кава чи чай? Що відповісти?", ["Tea, please.", "I'm fine, thanks.", "My name is Anna."], "Слово or означає «чи». Достатньо назвати напій і додати please.")])

lesson(2, "Можна мені меню?", "Покликати офіціанта, попросити меню й сказати, чого ви хочете.",
 "Дві головні фрази замовлення. Can I have…? — «Можна мені…?». I'd like… — «Я хотів би / хотіла б…». Обидві ввічливі, і до обох додають please. The ставлять, коли річ одна й зрозуміло яка: the menu — меню цього кафе.",
 [W("excuse me", "/ɪkˈskjuːz miː/", "phrase", "перепрошую (щоб звернутися)", "Excuse me!", "Перепрошую!"),
  W("can", "/kæn/", "verb", "могти", "Can I have a tea?", "Можна мені чай?"),
  W("have", "/hæv/", "verb", "мати, отримати", "Can I have the menu?", "Можна мені меню?"),
  W("menu", "/ˈmenjuː/", "noun", "меню", "The menu, please.", "Меню, будь ласка."),
  W("the", "/ðə/", "determiner", "цей, той самий (перед назвою речі)", "Can I have the menu?", "Можна мені меню?"),
  W("I'd like", "/aɪd laɪk/", "phrase", "я хотів би, я хотіла б", "I'd like a coffee, please.", "Я хотів би каву, будь ласка."),
  W("of course", "/əv ˈkɔːs/", "phrase", "звичайно", "Yes, of course.", "Так, звичайно."),
  W("here you are", "/ˌhɪə juː ˈɑː/", "phrase", "ось, будь ласка (коли щось дають)", "Here you are.", "Ось, будь ласка.")],
 [fb("Coffee ___ milk, please.", ["with", "in", "my"], "«З молоком» — with milk.", "Повторимо. Оберіть слово, якого бракує"),
  mc("Як звернутися до офіціанта?", ["Excuse me!", "Goodbye!", "Here you are."], "Excuse me — «перепрошую». Так привертають увагу незнайомої людини."),
  mt([("menu", "меню"), ("of course", "звичайно"), ("excuse me", "перепрошую"), ("I'd like", "я хотів би")], "Ці чотири вирази потрібні в кожному кафе й ресторані."),
  liu("Can I have the menu, please?", "Прослухайте. Що просить людина?", ["Меню", "Каву", "Воду"], "Can I have the menu? — «Можна мені меню?»"),
  fb("Can I ___ the menu, please?", ["have", "like", "are"], "Фраза завжди однакова: Can I have…?"),
  fb("I'd ___ a coffee, please.", ["like", "have", "can"], "I'd like — «я хотів би». Це ввічливіше, ніж I want — «я хочу»."),
  bs("Можна мені меню, будь ласка?", ["Can", "I", "have", "the", "menu", "please"], ["like", "a"], "Порядок слів: Can + I + have + the menu + please."),
  liu("Here you are.", "Офіціант приніс каву й каже це. Що це означає?", ["Ось, будь ласка", "Як справи?", "Ви тут?"], "Here you are кажуть, коли щось подають у руки. Відповідь — Thank you."),
  tr("Я хотів би чай, будь ласка.", ["I'd like a tea, please", "I would like a tea, please", "I'd like tea, please", "I would like tea, please"], "I'd like a tea, please. I'd — скорочення від I would."),
  li("Here you are.", "Вам подали каву. Що відповісти?", ["Thank you.", "Excuse me.", "Yes, please."], "Коли вам щось дають, кажуть Thank you.")])

lesson(3, "Щось поїсти", "Назвати просту їжу й замовити її.",
 "Їжу замовляють тими самими фразами: I'd like a sandwich, Can I have a salad? Слово or означає «чи, або»: A sandwich or a salad? Слово and — «і»: a coffee and a cake.",
 [W("sandwich", "/ˈsænwɪtʃ/", "noun", "сендвіч, бутерброд", "A sandwich, please.", "Сендвіч, будь ласка."),
  W("cake", "/keɪk/", "noun", "торт, тістечко", "A coffee and a cake.", "Каву й тістечко."),
  W("soup", "/suːp/", "noun", "суп", "I'd like the soup.", "Я хотів би суп."),
  W("salad", "/ˈsæləd/", "noun", "салат", "A salad, please.", "Салат, будь ласка."),
  W("bread", "/bred/", "noun", "хліб", "Soup with bread.", "Суп із хлібом."),
  W("cheese", "/tʃiːz/", "noun", "сир", "A cheese sandwich.", "Сендвіч із сиром."),
  W("chicken", "/ˈtʃɪkɪn/", "noun", "курка", "A chicken salad.", "Салат із куркою."),
  W("or", "/ɔː/", "conjunction", "чи, або", "Tea or coffee?", "Чай чи кава?")],
 [bs("Повторимо. Можна мені чай?", ["Can", "I", "have", "a", "tea"], ["like", "the"], "Can I have a tea? — «Можна мені чай?»"),
  mt([("sandwich", "сендвіч"), ("cake", "тістечко"), ("soup", "суп"), ("salad", "салат")], "Чотири найпростіші страви з меню кафе."),
  mt([("bread", "хліб"), ("cheese", "сир"), ("chicken", "курка"), ("or", "чи, або")], "Cheese і chicken починаються з того самого звука «ч»."),
  liu("A cheese sandwich, please.", "Прослухайте. Що замовляє людина?", ["Сендвіч із сиром", "Сендвіч із куркою", "Салат із сиром"], "A cheese sandwich — сендвіч із сиром. Слово, що описує, стоїть перед назвою страви."),
  mc("Як сказати «салат із куркою»?", ["a chicken salad", "a salad chicken", "a chicken or salad"], "Спочатку з чим, потім що: a chicken salad, a cheese sandwich."),
  fb("Soup ___ salad?", ["or", "with", "the"], "Or — «чи»: суп чи салат?"),
  fb("A coffee ___ a cake, please.", ["and", "or", "in"], "And — «і»: каву й тістечко."),
  bs("Я хотів би суп із хлібом.", ["I'd", "like", "soup", "with", "bread"], ["have", "or"], "I'd like + страва. «Із хлібом» — with bread."),
  tr("Сендвіч із куркою, будь ласка.", ["A chicken sandwich, please", "Chicken sandwich, please"], "A chicken sandwich, please."),
  li("Soup or salad?", "Вас питають. Що відповісти?", ["Soup, please.", "Yes, of course.", "I'm from Ukraine."], "Вас просять вибрати: суп чи салат. Назвіть одне й додайте please.")])

lesson(4, "Велика чи мала?", "Уточнити замовлення: розмір, гаряче чи холодне, і сказати «це все».",
 "Слова, що описують, стоять перед назвою: a large coffee, a cold juice. Якщо їх два, спочатку розмір: a large black coffee. Коли офіціант питає Anything else? — «Щось іще?», відповідають No, that's all, thanks.",
 [W("small", "/smɔːl/", "adjective", "малий", "A small coffee, please.", "Малу каву, будь ласка."),
  W("large", "/lɑːdʒ/", "adjective", "великий", "A large tea, please.", "Великий чай, будь ласка."),
  W("hot", "/hɒt/", "adjective", "гарячий", "Hot tea.", "Гарячий чай."),
  W("cold", "/kəʊld/", "adjective", "холодний", "Cold water, please.", "Холодної води, будь ласка."),
  W("black", "/blæk/", "adjective", "чорний", "A black coffee.", "Чорна кава."),
  W("white", "/waɪt/", "adjective", "білий; (про каву) з молоком", "A white coffee.", "Кава з молоком."),
  W("anything else", "/ˌeniθɪŋ ˈels/", "phrase", "щось іще?", "Anything else?", "Щось іще?"),
  W("that's all", "/ˌðæts ˈɔːl/", "phrase", "це все", "That's all, thanks.", "Це все, дякую.")],
 [fb("A cheese ___, please.", ["sandwich", "coffee", "water"], "A cheese sandwich — сендвіч із сиром.", "Повторимо. Оберіть слово, якого бракує"),
  mt([("small", "малий"), ("large", "великий"), ("hot", "гарячий"), ("cold", "холодний")], "Small — large і hot — cold: дві пари протилежних слів."),
  liu("A large black coffee, please.", "Прослухайте. Що замовляє людина?", ["Велику чорну каву", "Малу чорну каву", "Велику каву з молоком"], "Large — велика, black — чорна. Розмір стоїть першим."),
  mc("Як сказати «мала кава»?", ["a small coffee", "a coffee small", "small a coffee"], "Слово, що описує, стоїть між a і назвою: a small coffee."),
  mcu("У Британії просять a white coffee. Що вам принесуть?", ["Каву з молоком", "Каву без кофеїну", "Каву з цукром"], "White coffee — кава з молоком, black coffee — без молока."),
  fb("A ___ water, please.", ["cold", "black", "that's"], "Cold water — холодна вода."),
  liu("Anything else?", "Офіціант питає це після замовлення. Що це означає?", ["Щось іще?", "Усе добре?", "Ви тут?"], "Anything else? — «Щось іще?». Так перевіряють, чи ви все замовили."),
  bs("Ні, це все, дякую.", ["No", "that's", "all", "thanks"], ["else", "yes"], "No, that's all, thanks — стандартна відповідь на Anything else?"),
  tr("Малу каву, будь ласка.", ["A small coffee, please", "Small coffee, please"], "A small coffee, please."),
  li("Anything else?", "Ви хочете ще тістечко. Що відповісти?", ["Yes, a cake, please.", "No, that's all, thanks.", "Here you are."], "Якщо хочете ще щось — Yes і назва страви. Якщо ні — No, that's all.")])

lesson(5, "Скільки коштує?", "Спитати ціну, попросити рахунок і заплатити.",
 "How much is it? — «Скільки це коштує?». Відповідь починається з It's: It's five pounds. Щоб заплатити, просять рахунок: Can I have the bill, please? Карткою — by card, готівкою — in cash.",
 [W("how much", "/ˌhaʊ ˈmʌtʃ/", "phrase", "скільки (про ціну)", "How much is it?", "Скільки це коштує?"),
  W("it", "/ɪt/", "pronoun", "це, воно", "It's five pounds.", "Це коштує п'ять фунтів."),
  W("pound", "/paʊnd/", "noun", "фунт (гроші Британії)", "It's two pounds.", "Це коштує два фунти."),
  W("euro", "/ˈjʊərəʊ/", "noun", "євро", "It's three euros.", "Це коштує три євро."),
  W("bill", "/bɪl/", "noun", "рахунок", "Can I have the bill, please?", "Можна рахунок, будь ласка?"),
  W("pay", "/peɪ/", "verb", "платити", "Can I pay by card?", "Можна заплатити карткою?"),
  W("card", "/kɑːd/", "noun", "картка", "By card, please.", "Карткою, будь ласка."),
  W("cash", "/kæʃ/", "noun", "готівка", "Can I pay in cash?", "Можна заплатити готівкою?")],
 [li("Anything else?", "Повторимо. Ви більше нічого не хочете. Що відповісти?", ["No, that's all, thanks.", "Yes, of course.", "Excuse me."], "No, that's all, thanks — «ні, це все, дякую»."),
  mt([("bill", "рахунок"), ("card", "картка"), ("cash", "готівка"), ("pay", "платити")], "Чотири слова для кінця візиту: рахунок і два способи заплатити."),
  mc("Як спитати ціну?", ["How much is it?", "How are you?", "What's your name?"], "How much is it? — «Скільки це коштує?»"),
  liu("It's six pounds.", "Прослухайте. Скільки це коштує?", ["6 фунтів", "7 фунтів", "10 фунтів"], "Six — шість. It's six pounds — це коштує шість фунтів."),
  fb("How ___ is it?", ["much", "are", "like"], "Про ціну питають How much…?"),
  fb("Can I have the ___, please?", ["bill", "pay", "much"], "The bill — рахунок. Фраза та сама, що й для меню: Can I have…?"),
  liu("Card or cash?", "Вас питають це біля каси. Про що мова?", ["Карткою чи готівкою?", "Кава чи чай?", "Велика чи мала?"], "Card — картка, cash — готівка, or — чи."),
  bs("Можна заплатити карткою?", ["Can", "I", "pay", "by", "card"], ["have", "cash"], "Can I pay by card? Перед card ставлять by."),
  tr("Скільки це коштує?", ["How much is it", "How much is this"], "How much is it?"),
  li("It's four pounds, please.", "Вам назвали ціну. Як спитати, чи можна карткою?", ["Can I pay by card?", "How much is it?", "I'd like a coffee."], "Ціну ви вже знаєте, тому питаєте про спосіб оплати: Can I pay by card?")])

lesson(6, "Повторення: замовлення в кафе", "Пройти весь візит до кафе: від привітання до рахунку.",
 "Нових слів немає. Тут ціла розмова в кафе: привітатися, попросити меню, замовити напій і їжу, сказати «це все», спитати ціну й заплатити.",
 [],
 [li("Hello! How are you?", "Ви зайшли в кафе. Що відповісти?", ["Hello! I'm fine, thanks.", "Goodbye!", "That's all."], "На привітання відповідають привітанням, на How are you? — I'm fine, thanks."),
  bs("Можна мені меню, будь ласка?", ["Can", "I", "have", "the", "menu", "please"], ["pay", "bill"], "Can I have the menu, please?"),
  li("Here you are.", "Вам подали меню. Що відповісти?", ["Thank you.", "Excuse me.", "No, thank you."], "Коли вам щось подають — Thank you."),
  tr("Я хотів би велику каву з молоком.", ["I'd like a large coffee with milk", "I would like a large coffee with milk", "I'd like a large white coffee", "I would like a large white coffee"], "I'd like a large coffee with milk. У Британії можна сказати й a large white coffee."),
  li("Soup or salad?", "Що відповісти?", ["Salad, please.", "Yes, please.", "It's two pounds."], "Вас просять вибрати одне з двох."),
  fb("A chicken sandwich ___ a small tea, please.", ["and", "or", "by"], "And — «і»: сендвіч і чай."),
  li("Anything else?", "Ви замовили все. Що відповісти?", ["No, that's all, thanks.", "Yes, of course.", "How much?"], "No, that's all, thanks."),
  tr("Скільки це коштує?", ["How much is it", "How much is this"], "How much is it?"),
  liu("It's nine euros.", "Прослухайте. Скільки треба заплатити?", ["9 євро", "5 євро", "9 фунтів"], "Nine — дев'ять, euros — євро."),
  bs("Можна заплатити карткою?", ["Can", "I", "pay", "by", "card"], ["in", "bill"], "Can I pay by card?")],
 review=True)
