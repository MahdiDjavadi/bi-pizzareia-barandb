# تست 03: یکتایی، رابطه‌ها و معنای ستون‌های کلیدی

**فاز / مرحله:** P2 / S3 (+ بخشی از S5)

## هدف

آزمون یکتایی کلیدهایی که constraint ندارند، و بررسی اینکه رابطه‌های بین جدول‌های هسته در سطح داده برقرار هستند.

## کاری که انجام شد

- آزمون یکتایی و NULL بودن کلیدهای `orders.t_orderID`، `orderItems.ID`، `customers.t_customerID`، `HistoryFactors.t_orderID` و `products.t_productID`.
- شمارش orphan برای چهار رابطه: `orderItems → orders`، `orders → customers`، `HistoryFactors → orders` و `orderItems → products`.
- شمارش سفارش‌های بدون آیتم.
- بررسی توزیع ستون‌های وضعیت و کانال (`t_show`، `FactorType`، `fromMobile`، `SysName`، `t_paymentMethod`، `OnlineShopId`).

**اسکریپت:** `sql/discovery/t03_relationships_domains.sql`

## نتیجه

<div dir="rtl">

### کوئری T3.1 – یکتایی کلیدها  
*(کلیدهای اعلام‌شده وجود ندارند، بنابراین تست می‌شود)*

| key_name                | total_rows | distinct_keys | null_keys |
|-------------------------|------------|---------------|-----------|
| orders.t_orderID        | 17654      | 17654         | 0         |
| orderItems.ID           | 47525      | 47525         | 0         |
| customers.t_customerID  | 4181       | 4181          | 0         |
| HistoryFactors.t_orderID| 2016       | 1778          | 0         |
| product.t_productID     | 248        | 248           | 0         |

### کوئری T3.2 – روابط کاندید  
*(استفاده از EXISTS برای جلوگیری از تکثیر join)*

| relationship              | child_rows | null_refs | orphan_rows |
|---------------------------|------------|-----------|-------------|
| orderItems → orders       | 47525      | 0         | 0           |
| orders → customers        | 17654      | 0         | 0           |
| HistoryFactors → orders   | 2016       | 0         | 0           |
| orderItems → products     | 47525      | 0         | 0           |

### کوئری T3.3 – سفارش‌های بدون هیچ آیتم خطی

| order_rows | orders_without_items |
|------------|----------------------|
| 17654      | 0                    |

### کوئری T3.4 – توزیع مقادیر ستون‌های وضعیت/کانال  
*(فقط تعداد، بدون داده شخصی)*

| dim                  | val              | cnt   |
|----------------------|------------------|-------|
| FactorType           | 0                | 7322  |
| FactorType           | 1                | 5095  |
| FactorType           | 3                | 3303  |
| FactorType           | 2                | 1934  |
| fromMobile           | 0                | 17654 |
| OnlineShopId_is_set  | NOT NULL         | 17654 |
| SysName              | *(خالی)*         | 10663 |
| SysName              | DESKTOP-AR8JPIC  | 6991  |
| t_paymentMethod      | *(خالی)*         | 17654 |
| t_show               | 1                | 17136 |
| t_show               | 0                | 518   |

</div>

## نکته مهم

فرضیه: رابطه `orders → customers` بدون orphan است، ولی ممکن است بخش بزرگی از سفارش‌ها به یک «مشتری پیش‌فرض» وصل باشد. اگر چنین باشد، تحلیل رفتار مشتری باید جدا از آن انجام شود. توزیع `t_customerID` را در T09 می‌بینیم. نام ماشین در ستون `SysName` به‌دلیل محرمانگی ماسک شده است.

## تفسیر

- **تأییدشده:** کلیدهای `orders.t_orderID` (17,654)، `orderItems.ID` (47,525)، `customers.t_customerID` (4,181) و `products.t_productID` (248) در داده فعلی یکتا و بدون NULL هستند. یکتایی فقط در داده ثابت شده و constraint ندارد.
- **تأییدشده:** چهار رابطه `orderItems → orders`، `orders → customers`، `HistoryFactors → orders` و `orderItems → products` صفر NULL و صفر orphan دارند. این نشان می‌دهد در داده فعلی رابطه‌ها رعایت شده‌اند، اگرچه فقط 34 FK تعریف شده است.
- **تأییدشده:** هر سفارش حداقل یک آیتم دارد و هر آیتم به یک سفارش وصل است، پس رابطه سفارش–آیتم در داده 1:N است.
- **تأییدشده:** `HistoryFactors` دارای 2016 ردیف برای 1778 سفارش یکتا است (238 ردیف اضافه) و همه به سفارش‌های موجود برمی‌گردند. **محتمل:** این با Snapshot یا تاریخچه ویرایش سازگار است، نه فروش مستقل؛ فعلاً با `orders` جمع نمی‌شود.
- **تأییدشده:** `fromMobile` در همه ردیف‌ها 0 است و `t_paymentMethod` در همه ردیف‌ها خالی دیده می‌شود (NULL یا رشته خالی بودنش مشخص نیست). هر دو برای تحلیل کانال یا روش پرداخت بی‌فایده‌اند.
- **تأییدشده:** `SysName` دو حالت دارد: 10,663 خالی و 6,991 یک نام ماشین. **محتمل:** این برچسب دستگاه ثبت‌کننده است، نه کانال فروش.
- **محتمل:** `t_show = 0` برای 518 سفارش است و تعداد ردیف `BackFactors` هم 518 است (تخمین متادیتا)؛ احتمالاً سفارش برگشتی یا لغوشده. تا تطبیق ستون‌ها و شناسه‌ها قطعی نیست.
- **نامشخص:** `FactorType` چهار مقدار دارد (0 تا 3). فرضیه: نوع سفارش (حضوری، بیرون‌بر، ارسال)؛ باید با `t_driver`، `numberOfPeople` و `DriverAmount` سنجیده شود.
- **محتمل:** `OnlineShopId` در همه ردیف‌ها NOT NULL است و احتمالاً مقدار پیش‌فرض دارد؛ مقدارهایش را باید دید.
- **فرضیه:** پرداخت‌ها احتمالاً از `ReceivedDocuments` و `PaymentDocuments` می‌آیند.
## تصمیم

- **D-006:** <div dir="rtl">ستون‌های `fromMobile`، `t_paymentMethod` و `SysName` برای تحلیل کانال فروش یا روش پرداخت استفاده نشوند.</div>
- **D-007:** <div dir="rtl">یکتایی کلیدهای بدون constraint (`t_orderID`، `ID`، `t_customerID`، `t_productID`) در هر بارگذاری به لایه تحلیلی آزمون و خطاها ثبت شوند.</div>
<div dir="rtl"> وضعیت D-003 به «تأییدشده» تغییر کرد (رابطه 1:N در T03 اثبات شد). grain طبق D-004 هنوز باید اثبات شود.</div>
