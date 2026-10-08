#!/usr/bin/env bash
set -e

FORBIDDEN_PATTERN="(hook|kalyan|tabak|tobac|smok|vape|курит|кальян|табак|парит)"

echo "🔍 Проверка кодовой базы и ресурсов на отсутствие запрещенных слов..."

# Исключаем бинарные файлы (-I), GoogleService-Info.plist (системный конфиг с project_id от Google) и скрытые файлы
MATCHES=$(grep -riIE --exclude="GoogleService-Info.plist" "$FORBIDDEN_PATTERN" Sources Resources 2>/dev/null || true)

if [ -n "$MATCHES" ]; then
    echo "❌ ОШИБКА: Обнаружены запрещенные слова в проекте:"
    echo "$MATCHES"
    exit 1
fi

echo "✅ Проверка пройдена успешно: запрещенных слов не обнаружено."
exit 0
