#!/usr/bin/env bash
set -e

FORBIDDEN_PATTERN="(hook|kalyan|tabak|tobac|smok|vape|курит|кальян|табак|парит)"

echo "🔍 Проверка кодовой базы и ресурсов на отсутствие запрещенных слов..."

# Исходная политика сохраняет юридическое имя оператора и его контакты.
# Эти сведения не являются позициями меню; меню и остальные ресурсы проверяем целиком.
MATCHES=$(grep -riIE --exclude="GoogleService-Info.plist" --exclude="privacy-policy.json" "$FORBIDDEN_PATTERN" Sources Resources 2>/dev/null || true)

if [ -n "$MATCHES" ]; then
    echo "❌ ОШИБКА: Обнаружены запрещенные слова в проекте:"
    echo "$MATCHES"
    exit 1
fi

echo "✅ Проверка пройдена успешно: запрещенных слов не обнаружено."
exit 0
