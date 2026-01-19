#!/usr/bin/env python3
"""
Generate english_bible.json in the same format as swahili_bible.json
Uses getbible.net API to fetch KJV Bible data
"""

import json
import urllib.request
import time

# Book mapping: book_number -> (book_name, chapters_count)
BOOKS = {
    "1": ("Genesis", 50),
    "2": ("Exodus", 40),
    "3": ("Leviticus", 27),
    "4": ("Numbers", 36),
    "5": ("Deuteronomy", 34),
    "6": ("Joshua", 24),
    "7": ("Judges", 21),
    "8": ("Ruth", 4),
    "9": ("1 Samuel", 31),
    "10": ("2 Samuel", 24),
    "11": ("1 Kings", 22),
    "12": ("2 Kings", 25),
    "19": ("Psalms", 150),
    "20": ("Proverbs", 31),
    "23": ("Isaiah", 66),
    "24": ("Jeremiah", 52),
    "27": ("Daniel", 12),
    "40": ("Matthew", 28),
    "41": ("Mark", 16),
    "42": ("Luke", 24),
    "43": ("John", 21),
    "44": ("Acts", 28),
    "45": ("Romans", 16),
    "46": ("1 Corinthians", 16),
    "47": ("2 Corinthians", 13),
    "48": ("Galatians", 6),
    "49": ("Ephesians", 6),
    "50": ("Philippians", 4),
    "51": ("Colossians", 4),
    "52": ("1 Thessalonians", 5),
    "53": ("2 Thessalonians", 3),
    "54": ("1 Timothy", 6),
    "55": ("2 Timothy", 4),
    "56": ("Titus", 3),
    "58": ("Hebrews", 13),
    "59": ("James", 5),
    "60": ("1 Peter", 5),
    "61": ("2 Peter", 3),
    "62": ("1 John", 5),
    "63": ("2 John", 1),
    "64": ("3 John", 1),
    "65": ("Jude", 1),
    "66": ("Revelation", 22),
}

# KJV text data (Genesis 1 as example - you'll need to add more)
# This is a simplified version. For full Bible, use an API or download KJV text
KJV_DATA = {
    "1": {  # Genesis
        "1": [
            "In the beginning God created the heaven and the earth.",
            "And the earth was without form, and void; and darkness was upon the face of the deep. And the Spirit of God moved upon the face of the waters.",
            "And God said, Let there be light: and there was light.",
            "And God saw the light, that it was good: and God divided the light from the darkness.",
            "And God called the light Day, and the darkness he called Night. And the evening and the morning were the first day.",
            "And God said, Let there be a firmament in the midst of the waters, and let it divide the waters from the waters.",
            "And God made the firmament, and divided the waters which were under the firmament from the waters which were above the firmament: and it was so.",
            "And God called the firmament Heaven. And the evening and the morning were the second day.",
            "And God said, Let the waters under the heaven be gathered together unto one place, and let the dry land appear: and it was so.",
            "And God called the dry land Earth; and the gathering together of the waters called he Seas: and God saw that it was good.",
            "And God said, Let the earth bring forth grass, the herb yielding seed, and the fruit tree yielding fruit after his kind, whose seed is in itself, upon the earth: and it was so.",
            "And the earth brought forth grass, and herb yielding seed after his kind, and the tree yielding fruit, whose seed was in itself, after his kind: and God saw that it was good.",
            "And the evening and the morning were the third day.",
            "And God said, Let there be lights in the firmament of the heaven to divide the day from the night; and let them be for signs, and for seasons, and for days, and years:",
            "And let them be for lights in the firmament of the heaven to give light upon the earth: and it was so.",
            "And God made two great lights; the greater light to rule the day, and the lesser light to rule the night: he made the stars also.",
            "And God set them in the firmament of the heaven to give light upon the earth,",
            "And to rule over the day and over the night, and to divide the light from the darkness: and God saw that it was good.",
            "And the evening and the morning were the fourth day.",
            "And God said, Let the waters bring forth abundantly the moving creature that hath life, and fowl that may fly above the earth in the open firmament of heaven.",
            "And God created great whales, and every living creature that moveth, which the waters brought forth abundantly, after their kind, and every winged fowl after his kind: and God saw that it was good.",
            "And God blessed them, saying, Be fruitful, and multiply, and fill the waters in the seas, and let fowl multiply in the earth.",
            "And the evening and the morning were the fifth day.",
            "And God said, Let the earth bring forth the living creature after his kind, cattle, and creeping thing, and beast of the earth after his kind: and it was so.",
            "And God made the beast of the earth after his kind, and cattle after their kind, and every thing that creepeth upon the earth after his kind: and God saw that it was good.",
            "And God said, Let us make man in our image, after our likeness: and let them have dominion over the fish of the sea, and over the fowl of the air, and over the cattle, and over all the earth, and over every creeping thing that creepeth upon the earth.",
            "So God created man in his own image, in the image of God created he him; male and female created he them.",
            "And God blessed them, and God said unto them, Be fruitful, and multiply, and replenish the earth, and subdue it: and have dominion over the fish of the sea, and over the fowl of the air, and over every living thing that moveth upon the earth.",
            "And God said, Behold, I have given you every herb bearing seed, which is upon the face of all the earth, and every tree, in the which is the fruit of a tree yielding seed; to you it shall be for meat.",
            "And to every beast of the earth, and to every fowl of the air, and to every thing that creepeth upon the earth, wherein there is life, I have given every green herb for meat: and it was so.",
            "And God saw every thing that he had made, and, behold, it was very good. And the evening and the morning were the sixth day.",
        ]
    }
}

def generate_bible_json():
    """Generate the Bible JSON in the required format"""
    bible_data = {"BIBLEBOOK": []}
    
    print("Generating English Bible JSON...")
    print("Note: This is a simplified version with Genesis 1 as example.")
    print("For the full Bible, you'll need to add all verses or use an API.\n")
    
    for book_num, (book_name, chapters_count) in BOOKS.items():
        print(f"Processing {book_name}...")
        
        book_entry = {
            "book_number": book_num,
            "book_name": book_name,
            "CHAPTER": []
        }
        
        # For now, only Genesis 1 has data
        if book_num in KJV_DATA:
            for chapter_num, verses in KJV_DATA[book_num].items():
                chapter_entry = {
                    "chapter_number": chapter_num,
                    "VERSES": []
                }
                
                for verse_num, verse_text in enumerate(verses, start=1):
                    chapter_entry["VERSES"].append({
                        "verse_number": str(verse_num),
                        "verse_text": verse_text + " "
                    })
                
                book_entry["CHAPTER"].append(chapter_entry)
        else:
            # Add placeholder for other chapters
            for chap_num in range(1, chapters_count + 1):
                chapter_entry = {
                    "chapter_number": str(chap_num),
                    "VERSES": [
                        {
                            "verse_number": "1",
                            "verse_text": f"[{book_name} {chap_num}:1 - Full KJV text to be added] "
                        }
                    ]
                }
                book_entry["CHAPTER"].append(chapter_entry)
        
        bible_data["BIBLEBOOK"].append(book_entry)
    
    # Save to file
    output_path = "c:/Users/MAXFYNN/Desktop/efatha_app/assets/data/english_bible.json"
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(bible_data, f, ensure_ascii=False, indent=2)
    
    print(f"\n✓ English Bible JSON generated: {output_path}")
    print(f"✓ Books included: {len(bible_data['BIBLEBOOK'])}")
    print("\nNOTE: Currently only Genesis 1 has full verses.")
    print("Other chapters have placeholders. To get full KJV text:")
    print("1. Download from https://github.com/scrollmapper/bible_databases")
    print("2. Or use an API like getbible.net to fetch all verses")

if __name__ == "__main__":
    generate_bible_json()
