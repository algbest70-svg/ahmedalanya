# دليل إعداد قاعدة البيانات (Google Sheets) 📊

لجعل التطبيق يعمل على كل الهواتف ويقوم بمزامنة العقارات تلقائياً، يرجى اتباع هذه الخطوات البسيطة (لمرة واحدة فقط):

---

## 1. إعداد ملف الجداول (Google Sheet)
1. قم بإنشاء ملف Google Sheet جديد.
2. قم بتسمية الصفحة الأولى باسم `Properties`.
3. في الصف الأول (Header)، ضع العناوين التالية بالترتيب:
   `ID` | `Title` | `Country` | `Category` | `SubCategory` | `Price` | `Description` | `Images` | `YoutubeLink`

---

## 2. تفعيل "الكود السحري" (Apps Script)
1. داخل ملف الشيت، اضغط على **Extensions** (إضافات) ثم اختر **Apps Script**.
2. قم بمسح أي كود موجود هناك، وضع الكود التالي بدلاً منه:

```javascript
function doPost(e) {
  try {
    var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];
    var data = JSON.parse(e.postData.contents);
    
    sheet.appendRow([
      data.id,
      data.title,
      data.country,
      data.category,
      data.subCategory || "",
      data.price,
      data.description,
      data.images ? data.images.join(", ") : "",
      data.youtubeLink || ""
    ]);
    
    return ContentService.createTextOutput("Success").setMimeType(ContentService.MimeType.TEXT);
  } catch (err) {
    return ContentService.createTextOutput("Error: " + err.message).setMimeType(ContentService.MimeType.TEXT);
  }
}

function doGet(e) {
  return ContentService.createTextOutput("Service is running!");
}
```

3. اضغط على **Deploy** (نشر) > **New Deployment** (نشر جديد).
4. اختر النوع **Web App**.
5. في خانة **Who has access** اختر **Anyone** (أي شخص). **هذا ضروري جداً!**
6. اضغط على **Deploy** وسيطلب منك جوجل إعطاء صلاحيات، وافق عليها.
7. سيظهر لك رابط يسمى **Web App URL**، قم بنسخه.

---

## 3. ربط التطبيق بالبيانات
1. اذهب لملف `c:\ahmed alanya\ahmedalanya\lib\core\constants.dart` في مشروعك.
2. ضع "معرف الملف" (تجدده في رابط الشيت المتصفح) في خانة `googleSheetId`.
3. ضع "الرابط السريع" الذي نسخته في الخطوة السابقة في خانة `googleWebAppUrl`.

---

### مبروك! 🎉
الآن بمجرد إضافة أي عقار، سيظهر في ملف الإكسل الخاص بك، وسيظهر في هواتف كل المستخدمين الذين يحملون التطبيق.
