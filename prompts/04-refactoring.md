# ♻️ Safe Refactoring

**When to use:**  
The code works, but needs restructuring. You need the AI to clean the codebase without silently deleting features, breaking interfaces, or violating architectural decisions.

---

### English Prompt 🇺🇸
> "I want to refactor [file/component]. Before making changes, execute your boot sequence and read the stack-rules. Ensure your refactoring does not violate existing ADRs or Integration Contracts. Outline the steps you will take and ensure we have verified tests before altering the structure."

### German Prompt 🇩🇪
> "Ich möchte [Komponente/Datei] refactoren. Führe zuerst deine Boot-Sequenz aus und lies die Stack-Rules. Stelle sicher, dass unser Refactoring keine bestehenden ADRs oder Integration Contracts bricht. Liste mir in Spiegelstrichen auf, wie du vorgehst, und stelle sicher, dass wir Tests haben, bevor du die Logik änderst."

### Russian Prompt 🇷🇺
> "Я хочу провести рефакторинг [файл/компонента]. Перед внесением изменений выполни Boot-последовательность и прочитай stack-rules. Убедись, что твой рефакторинг не нарушает существующие ADR или Integration Contracts. Опиши по шагам, что ты будешь делать, и убедись, что у нас есть тесты до изменения логики."
