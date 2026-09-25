with open("lib/main.dart", "r") as f:
    text = f.read()

# Replace any remote food image with pure veg eco icon
import re
text = re.sub(r'Image\.network\(.*?\)', 'Container(width: 90, height: 80, decoration: BoxDecoration(color: Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.eco, color: Color(0xFF0F8A65), size: 36))', text, flags=re.DOTALL)
with open("lib/main.dart", "w") as f:
    f.write(text)
print("Updated successfully")
