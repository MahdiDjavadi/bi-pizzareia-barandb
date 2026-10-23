<div dir="rtl">

| تست | فایل SQL | خروجی |
|---|---|---|
| T01 | `sql/discovery/t01_restore_integrity.sql` | بازیابی فایل بکآپ و بررسی سلامت دیتابیس |
| T02 | `sql/discovery/t02_inventory_candidates.sql` | شناسایی جداول و بررسی کلیدهای احتمالی |
| T03 | `sql/discovery/t03_relationships_domains.sql` | یکتایی کلیدها، رابطه‌ها و توزیع ستون‌های وضعیت |
| T04 | `sql/discovery/t04_date_coverage.sql` | بازه زمانی تراکنش‌ها، حجم ماهانه، gapها و کامل‌بودن روزهای آخر |
| T05 | `sql/discovery/t05_date_semantics_hour_distribution.sql` | معنای تاریخ‌ها، تاریخچه ویرایش، ستون‌های تاریخ جدول‌های فعالیت و توزیع ساعتی |
| T06 | `sql/discovery/t06_activity_inside_gaps.sql` | فعالیت ده جدول در داخل و اطراف gapها و روزهای تک‌روزه بدون سفارش |
| T07 | `sql/discovery/t07_grain_money_columns.sql` | grain خط‌ها، پروفایل ستون‌های پولی، مقایسه جمع هدر با خط‌ها و جدول‌های کاندید محصول |

</div>
