# 🐞 Structured Debugging

**When to use:**  
You hit a complicated bug, error log, or system failure. You want to stop the AI from making wild guesses and instead force it into a methodical, step-by-step verification logic.

---

### English Prompt 🇺🇸
> "We have a bug. Let's practice structured debugging according to AGENT.md. Do not write fix-code immediately. First, read any related integration contracts. Second, form a falsifiable hypothesis. Third, write a small test or command (`rtk`) to prove your hypothesis. Wait for my confirmation."

### German Prompt 🇩🇪
> "Wir haben einen Bug. Ich möchte strukturiertes Debugging gemäß AGENT.md. Schreibe noch keinen Fix! Lies zuerst relevante Integration Contracts aus dem Memory. Bilde dann eine überprüfbare Hypothese und nutze `rtk` (oder einen sauberen Testbefehl), um diese Hypothese zu beweisen. Warte auf meine Freigabe."

### Russian Prompt 🇷🇺
> "У нас баг. Давай проведем структурированный дебаггинг согласно AGENT.md. Не пиши код исправления сразу. Сначала прочитай контракты интеграций в Memory. Затем сформулируй проверяемую гипотезу и напиши небольшой тест (или команду `rtk`), чтобы ее подтвердить. Дождись моего подтверждения."
