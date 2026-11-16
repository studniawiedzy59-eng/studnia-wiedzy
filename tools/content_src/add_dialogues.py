"""Adds live 'dialogue' scenes to chosen review lessons (idempotent)."""
import json, pathlib
D = pathlib.Path("/home/claude/studnia-wiedzy/assets/content/en/lessons")
def uk(t): return {"uk": t}
def dlg(name, avatar, sit, line, options, why):
    return {"type": "dialogue", "prompt": uk(sit), "character": {"name": uk(name), "avatar": avatar},
            "line": line, "options": options, "answer": 0, "explanation": uk(why)}
S = {
 "u02_l06": [
  dlg("Бариста Том", "👨‍🍳", "Ви в кав'ярні. Хочете каву з молоком.", "Hi! What can I get you?",
      ["Can I have a coffee with milk, please?", "I want coffee with milk.", "Give me a coffee milk."],
      "Can I have…, please? — ввічливе замовлення. «I want…» звучить різко, а «Give me…» — як наказ."),
  dlg("Бариста Том", "👨‍🍳", "Бариста питає про розмір. Вам потрібна велика.", "Small or large?",
      ["Large, please.", "I am large.", "Big one, I think so."],
      "На такі питання відповідають коротко: Large, please. Зайві слова звучать дивно."),
  dlg("Бариста Том", "👨‍🍳", "Більше вам нічого не треба.", "Anything else?",
      ["No, that's all, thanks.", "No, I don't want anything.", "It's all me."],
      "That's all, thanks — стандартна відповідь. «I don't want anything» звучить грубувато."),
 ],
 "u11_l06": [
  dlg("Продавчиня Анна", "👩‍💼", "Ви лише дивитеся, купувати поки не збираєтеся.", "Hello! Can I help you?",
      ["Just looking, thanks.", "I only look.", "No help, thank you."],
      "Just looking, thanks — що кажуть усі в магазині. «I only look» — калька."),
  dlg("Продавчиня Анна", "👩‍💼", "Ви хочете приміряти куртку.", "Do you want to try it on?",
      ["Yes, where is the fitting room?", "Yes, where is the room for trying?", "Yes, I try on."],
      "Приміряльня — fitting room. Дослівне «room for trying» носії не зрозуміють."),
  dlg("Продавчиня Анна", "👩‍💼", "Ви хочете заплатити карткою.", "That's twenty pounds. Cash or card?",
      ["Card, please.", "With the card.", "I pay card."],
      "Коротко й ввічливо: Card, please. Артикль і «with» тут не потрібні."),
 ],
 "u22_l06": [
  dlg("Турист", "🧳", "Турист питає дорогу. Ви знаєте: прямо, потім ліворуч.", "Excuse me, do you know where the station is?",
      ["Yes, go straight and turn left.", "Yes, you go on straight and left turn.", "Yes, it is there."],
      "Go straight and turn left — чіткий порядок дій. «It is there» нічого не пояснює."),
  dlg("Турист", "🧳", "До станції приблизно п'ять хвилин пішки.", "Is it far from here?",
      ["No, it's only five minutes.", "No, it is five minutes by my feet.", "No, it isn't far, five minute."],
      "No, it's only five minutes — природно. «By my feet» — калька з української."),
  dlg("Турист", "🧳", "Турист дякує вам за допомогу.", "Thank you so much!",
      ["You're welcome!", "Please!", "No problem you."],
      "На Thank you відповідають You're welcome! Окреме Please! так не використовується."),
 ],
 "u28_l06": [
  dlg("Офіціантка Емма", "👩‍🍳", "Ви прийшли в ресторан удвох.", "Good evening! Table for two?",
      ["Yes, a table for two, please.", "Yes, we are two persons.", "Yes, give us table."],
      "Кажемо a table for two, please. «Two persons» — калька, носії так не кажуть."),
  dlg("Офіціантка Емма", "👩‍🍳", "Ви хочете замовити стейк.", "Are you ready to order?",
      ["Yes, I'll have the steak, please.", "Yes, I will to have steak.", "Yes, bring me steak."],
      "I'll have… — природне замовлення. Після will не ставимо to, а «bring me» звучить як наказ."),
  dlg("Офіціантка Емма", "👩‍🍳", "Вам потрібна вода без газу.", "Still or sparkling water?",
      ["Still, please.", "Without gas, please.", "Quiet water, please."],
      "Вода без газу — still water. «Without gas» і «quiet» — кальки з української."),
 ],
 "u36_l06": [
  dlg("Друг Том", "🧑", "Друг запрошує вас на вечірку. Ви раді.", "Hey! Would you like to come to my party on Saturday?",
      ["I'd love to! What time?", "Yes, I like to come.", "I will come, thank you very."],
      "I'd love to! — тепла згода. «I like to come» звучить так, ніби йдеться про звичку."),
  dlg("Друг Том", "🧑", "Том пропонує зустрітися о сьомій. Вам підходить.", "Shall we meet at seven?",
      ["Good idea. See you there!", "Yes, we shall meet.", "I agree with you idea."],
      "Good idea. See you there! — коротко й по-дружньому."),
  dlg("Друг Том", "🧑", "Том просить принести щось випити. Ви принесете сік.", "Can you bring something to drink?",
      ["Of course! I'll bring juice.", "Yes, I bring something drink.", "Of course, I can to bring."],
      "I'll bring… — обіцянка на місці. Після can не ставимо to."),
 ],
}

S.update({
 "u10_l06": [
  dlg("Подруга Лена", "👩", "Ви голодні й любите піцу.", "Are you hungry? We have pizza and salad.",
      ["Yes, I'm hungry! Pizza, please.", "Yes, I have hunger. Pizza me.", "I am hungry for pizza yes."],
      "I'm hungry — так кажуть про голод. «I have hunger» — калька з української."),
  dlg("Подруга Лена", "👩", "Ви вже наїлися.", "Would you like some more rice?",
      ["No, thank you. I'm full.", "No, thanks. I am satisfied.", "No more, I ate enough."],
      "I'm full — природно про ситість. «Satisfied» звучить книжково."),
  dlg("Подруга Лена", "👩", "Ви хочете води.", "What would you like to drink?",
      ["Just water, please.", "Only water, thank you very.", "Water to me, please."],
      "Just water, please — коротко й ввічливо. «Thank you very» — незакінчена фраза."),
 ],
 "u23_l06": [
  dlg("Перехожий", "🧑‍🦱", "Ви не знаєте, де бібліотека.", "You look lost. Can I help?",
      ["Yes, please. Where is the library?", "Yes, tell me where library.", "Yes, where is library?"],
      "Yes, please. Where is the library? — ввічливо й з артиклем the."),
  dlg("Перехожий", "🧑‍🦱", "Ви зрозуміли шлях і хочете подякувати.", "Go straight on, then turn left. You can't miss it.",
      ["Thanks a lot!", "Thanks for your attention.", "I understand you, thanks."],
      "Thanks a lot! — тепла коротка подяка. «For your attention» — калька."),
  dlg("Перехожий", "🧑‍🦱", "Ви хочете перепитати, чи правильно зрозуміли шлях: прямо й ліворуч.", "It's a five-minute walk.",
      ["So, straight on, then left?", "So, I must go right?", "Left, then straight, you said?"],
      "So, …? — природний спосіб перепитати. Інші варіанти плутають напрямок."),
 ],
 "u26_l06": [
  dlg("Працівниця аеропорту", "👩‍✈️", "Ви на реєстрації й подаєте паспорт.", "Good morning! Passport, please.",
      ["Here you are.", "Take it.", "This is mine."],
      "Here you are — те, що кажуть, коли щось передають."),
  dlg("Працівниця аеропорту", "👩‍✈️", "У вас одна валіза.", "Do you have any bags to check in?",
      ["Yes, one suitcase.", "Yes, I have one suitcase to give.", "One suitcase only I have."],
      "Достатньо Yes, one suitcase. Зайві слова звучать неприродно."),
  dlg("Працівниця аеропорту", "👩‍✈️", "Ви не розчули час посадки.", "Your gate is number twelve. Boarding starts at nine.",
      ["Sorry, what time?", "Sorry, what is time?", "Repeat, please time."],
      "Sorry, what time? — ввічливе перепитування. «What is time?» означає зовсім інше."),
 ],
 "u27_l06": [
  dlg("Адміністратор готелю", "🧑‍💼", "У вас є бронь на прізвище Kovalenko.", "Good evening! Do you have a booking?",
      ["Yes, under the name Kovalenko.", "Yes, on surname Kovalenko.", "Yes, my booking is Kovalenko by."],
      "Бронь «на ім'я» — under the name. «On surname» — калька."),
  dlg("Адміністратор готелю", "🧑‍💼", "Ви хочете дізнатися пароль від Wi-Fi.", "Here is your key card. Breakfast is included.",
      ["Thank you. What's the Wi-Fi password?", "Thank you. Say me the password for wifi.", "Thanks. Password for internet is what?"],
      "What's the Wi-Fi password? — стандартне запитання. «Say me» — помилка, потрібно «tell me»."),
  dlg("Адміністратор готелю", "🧑‍💼", "У номері не працює опалення.", "Is everything OK with your room?",
      ["Actually, the heating doesn't work.", "Not okay, heating is broken at me.", "No, I have problem heating."],
      "Actually, … — м'який спосіб поскаржитися. «At me» і «I have problem heating» — кальки."),
 ],
 "u33_l06": [
  dlg("Фармацевтка", "👩‍⚕️", "У вас болить голова.", "Hello! How can I help you?",
      ["I have a headache. Do you have anything for it?", "My head is hurting, give me something.", "I have pain of head."],
      "I have a headache — стандартна фраза. Anything for it? — природне прохання."),
  dlg("Фармацевтка", "👩‍⚕️", "У вас немає алергії.", "Do you have any allergies?",
      ["No, I'm not allergic to anything.", "No, I don't have allergy.", "No, I haven't allergy."],
      "I'm allergic to… — стала фраза. «Have allergy» без артикля й форми — помилка."),
  dlg("Фармацевтка", "👩‍⚕️", "Ви хочете спитати, скільки разів на день.", "Take one tablet after a meal, with water.",
      ["How many times a day?", "How much times per day?", "Many times in a day?"],
      "Times лічильне, тому How many times a day? Усе інше — кальки."),
 ],
})
from dialogues_more import M
for lid, items in M.items():
    S[lid] = [dlg(*t) for t in items]
for lid, items in S.items():
    p = D / f"{lid}.json"
    d = json.loads(p.read_text())
    d["exercises"] = [e for e in d["exercises"] if e["type"] != "dialogue"]
    n = len(d["exercises"])
    for i, it in enumerate(items, 1):
        d["exercises"].append(dict(id=f"e{n + i}", **it))
    p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + "\n")
print("ok")
