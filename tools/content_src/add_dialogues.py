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
for lid, items in S.items():
    p = D / f"{lid}.json"
    d = json.loads(p.read_text())
    d["exercises"] = [e for e in d["exercises"] if e["type"] != "dialogue"]
    n = len(d["exercises"])
    for i, it in enumerate(items, 1):
        d["exercises"].append(dict(id=f"e{n + i}", **it))
    p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + "\n")
print("ok")
