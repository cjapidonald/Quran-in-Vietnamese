#!/usr/bin/env python3
"""Generate bundled Quran data with Arabic text and Vietnamese translation."""
from __future__ import annotations

import json
import pathlib
import sys
import urllib.request
from datetime import UTC, datetime
from typing import Dict, List

ARABIC_VERSES_URL = "https://raw.githubusercontent.com/fawazahmed0/quran-api/1/database/linebyline/ara-quranuthmanihaf.txt"
VIETNAMESE_VERSES_URL = "https://raw.githubusercontent.com/fawazahmed0/quran-api/1/database/linebyline/vie-hassanabdulkari.txt"
SURA_METADATA_URL = "https://raw.githubusercontent.com/semarketir/quranjson/master/source/surah.json"

OUTPUT_PATH = pathlib.Path(__file__).resolve().parents[1] / "Quranvn" / "Resources" / "quran.json"

VIETNAMESE_SURA_NAMES: Dict[int, str] = {
    1: "Al-Fātiḥah — Lời Mở Đầu",
    2: "Al-Baqarah — Con Bò Cái",
    3: "Āl ʿImrān — Gia Đình Imran",
    4: "An-Nisāʾ — Phụ Nữ",
    5: "Al-Mā'idah — Bàn Tiệc",
    6: "Al-An'ām — Đàn Gia Súc",
    7: "Al-A'rāf — Thành Trì Cao",
    8: "Al-Anfāl — Chiến Lợi Phẩm",
    9: "At-Tawbah — Sám Hối",
    10: "Yūnus — Ngôn Sứ Yunus",
    11: "Hūd — Ngôn Sứ Hud",
    12: "Yūsuf — Ngôn Sứ Yusuf",
    13: "Ar-Ra'd — Sấm Sét",
    14: "Ibrāhīm — Ngôn Sứ Ibrahim",
    15: "Al-Ḥijr — Vùng Đá",
    16: "An-Naḥl — Đàn Ong",
    17: "Al-Isrāʾ — Hành Trình Ban Đêm",
    18: "Al-Kahf — Hang Động",
    19: "Maryam — Maryam",
    20: "Ṭā Hā — Tā Hā",
    21: "Al-Anbiyāʾ — Các Ngôn Sứ",
    22: "Al-Ḥajj — Hành Hương",
    23: "Al-Mu'minūn — Những Người Có Đức Tin",
    24: "An-Nūr — Ánh Sáng",
    25: "Al-Furqān — Tiêu Chuẩn",
    26: "Ash-Shu'arāʼ — Các Thi Sĩ",
    27: "An-Naml — Kiến",
    28: "Al-Qaṣaṣ — Những Câu Chuyện",
    29: "Al-ʿAnkabūt — Nhện",
    30: "Ar-Rūm — Người La Mã",
    31: "Luqmān — Luqman",
    32: "As-Sajdah — Sự Sụp Lạy",
    33: "Al-Aḥzāb — Các Đồng Minh",
    34: "Sabaʼ — Saba",
    35: "Fāṭir — Đấng Kiến Tạo",
    36: "Yā Sīn — Yā Sīn",
    37: "As-Ṣāffāt — Các Hàng Ngũ",
    38: "Ṣād — Ṣād",
    39: "Az-Zumar — Đoàn Đoàn",
    40: "Ghāfir — Đấng Tha Thứ",
    41: "Fuṣṣilat — Những Lời Giải Thích",
    42: "Ash-Shūrā — Hội Đồng",
    43: "Az-Zukhruf — Trang Sức Vàng",
    44: "Ad-Dukhān — Khói",
    45: "Al-Jāthiyah — Quỳ Gối",
    46: "Al-Aḥqāf — Cồn Cát",
    47: "Muḥammad — Muhammad",
    48: "Al-Fatḥ — Chiến Thắng",
    49: "Al-Ḥujurāt — Những Phòng Riêng",
    50: "Qāf — Qāf",
    51: "Adh-Dhāriyāt — Những Cơn Gió Cuốn",
    52: "Aṭ-Ṭūr — Núi Sinai",
    53: "An-Najm — Ngôi Sao",
    54: "Al-Qamar — Mặt Trăng",
    55: "Ar-Raḥmān — Đấng Rất Mực Khoan Dung",
    56: "Al-Wāqi'ah — Biến Cố",
    57: "Al-Ḥadīd — Sắt",
    58: "Al-Mujādilah — Người Nữ Tranh Luận",
    59: "Al-Ḥashr — Sự Di Tản",
    60: "Al-Mumtaḥanah — Người Bị Thử Thách",
    61: "Aṣ-Ṣaff — Hàng Ngũ",
    62: "Al-Jumu'ah — Buổi Cầu Nguyện Thứ Sáu",
    63: "Al-Munāfiqūn — Những Kẻ Đạo Đức Giả",
    64: "At-Taghābun — Sự Gian Lận",
    65: "Aṭ-Ṭalāq — Ly Dị",
    66: "At-Taḥrīm — Sự Cấm Đoán",
    67: "Al-Mulk — Vương Quyền",
    68: "Al-Qalam — Cây Bút",
    69: "Al-Ḥāqqah — Sự Chắc Chắn",
    70: "Al-Ma'ārij — Những Cấp Bậc",
    71: "Nūḥ — Ngôn Sứ Nuh",
    72: "Al-Jinn — Các Jinn",
    73: "Al-Muzzammil — Người Trùm Áo",
    74: "Al-Muddaththir — Người Choàng Áo",
    75: "Al-Qiyāmah — Ngày Phục Sinh",
    76: "Al-Insān — Con Người",
    77: "Al-Mursalāt — Những Sứ Giả",
    78: "An-Nabaʼ — Tin Tức Lớn",
    79: "An-Nāzi'āt — Những Người Giật Ra",
    80: "ʿAbasa — Người Cau Mày",
    81: "At-Takwīr — Cuộn Lại",
    82: "Al-Infiṭār — Tách Đôi",
    83: "Al-Muṭaffifīn — Những Kẻ Gian Lận Cân Đo",
    84: "Al-Inshiqāq — Nứt Ra",
    85: "Al-Burūj — Chòm Sao",
    86: "Aṭ-Ṭāriq — Sao Băng",
    87: "Al-A'lā — Đấng Tối Cao",
    88: "Al-Ghāshiyah — Sự Bao Trùm",
    89: "Al-Fajr — Bình Minh",
    90: "Al-Balad — Thành Phố",
    91: "Ash-Shams — Mặt Trời",
    92: "Al-Layl — Đêm",
    93: "Aḍ-Ḍuḥā — Ánh Ban Mai",
    94: "Ash-Sharḥ — Sự Mở Rộng",
    95: "At-Tīn — Quả Vả",
    96: "Al-ʿAlaq — Phôi Thai",
    97: "Al-Qadr — Đêm Định Mệnh",
    98: "Al-Bayyinah — Bằng Chứng Rõ Ràng",
    99: "Az-Zalzalah — Động Đất",
    100: "Al-ʿĀdiyāt — Những Chiến Mã",
    101: "Al-Qāri'ah — Thảm Họa",
    102: "At-Takāthur — Sự Đua Tranh",
    103: "Al-ʿAṣr — Buổi Chiều",
    104: "Al-Humazah — Kẻ Chỉ Trích",
    105: "Al-Fīl — Con Voi",
    106: "Quraysh — Bộ Tộc Quraysh",
    107: "Al-Mā'ūn — Đồ Dùng Cần Thiết",
    108: "Al-Kawthar — Sự Dồi Dào",
    109: "Al-Kāfirūn — Những Kẻ Không Tin",
    110: "An-Naṣr — Sự Chi Viện",
    111: "Al-Masad — Dây Thừng Bện",
    112: "Al-Ikhlāṣ — Sự Thuần Khiết",
    113: "Al-Falaq — Rạng Đông",
    114: "An-Nās — Loài Người",
}


def fetch_lines(url: str) -> List[str]:
    with urllib.request.urlopen(url) as response:
        content = response.read().decode("utf-8")
    lines = [line.strip() for line in content.splitlines()]
    return [line for line in lines if line]


def split_content(lines: List[str]) -> List[str]:
    """Return verse lines without trailing metadata block."""
    if not lines:
        return lines
    # Detect metadata block at the end (starts with '{' line).
    for idx in range(len(lines) - 1, -1, -1):
        if lines[idx].startswith("{"):
            return lines[:idx]
    return lines


def extract_metadata(lines: List[str]) -> Dict[str, str]:
    for idx in range(len(lines) - 1, -1, -1):
        if lines[idx].startswith("{"):
            metadata_raw = "\n".join(lines[idx:])
            try:
                return json.loads(metadata_raw)
            except json.JSONDecodeError:
                return {}
    return {}


def fetch_json(url: str):
    with urllib.request.urlopen(url) as response:
        return json.load(response)


def build_output(arabic: List[str], vietnamese: List[str], surah_meta, arabic_meta, vietnamese_meta):
    if len(arabic) != len(vietnamese):
        raise SystemExit(f"Arabic ({len(arabic)}) and Vietnamese ({len(vietnamese)}) lines mismatch")

    total_verses = sum(int(item["count"]) for item in surah_meta)
    if total_verses != len(arabic):
        raise SystemExit(
            f"Verse count mismatch: metadata {total_verses} vs lines {len(arabic)}"
        )

    index = 0
    surahs = []
    for entry in surah_meta:
        surah_number = int(entry["index"])
        verse_count = int(entry["count"])
        arabic_chunk = arabic[index : index + verse_count]
        vietnamese_chunk = vietnamese[index : index + verse_count]
        if len(arabic_chunk) != verse_count or len(vietnamese_chunk) != verse_count:
            raise SystemExit(f"Unexpected verse chunk length for surah {surah_number}")

        ayahs = []
        for offset, (arabic_text, vietnamese_text) in enumerate(zip(arabic_chunk, vietnamese_chunk), start=1):
            ayahs.append(
                {
                    "id": f"{surah_number}:{offset}",
                    "number": offset,
                    "arabic": arabic_text,
                    "vietnamese": vietnamese_text,
                }
            )

        surahs.append(
            {
                "number": surah_number,
                "arabicName": entry.get("titleAr", ""),
                "transliteration": entry.get("title", ""),
                "revelationPlace": entry.get("place", ""),
                "revelationOrder": entry.get("order"),
                "page": entry.get("pages"),
                "vietnameseName": VIETNAMESE_SURA_NAMES.get(surah_number, entry.get("title", "")),
                "ayahs": ayahs,
            }
        )
        index += verse_count

    return {
        "metadata": {
            "generatedAt": datetime.now(UTC).date().isoformat(),
            "arabicSource": arabic_meta,
            "vietnameseSource": vietnamese_meta,
            "structureSource": {
                "name": "semarketir/quranjson",
                "url": SURA_METADATA_URL,
            },
        },
        "surahs": surahs,
    }


def main() -> None:
    arabic_lines_full = fetch_lines(ARABIC_VERSES_URL)
    vietnamese_lines_full = fetch_lines(VIETNAMESE_VERSES_URL)

    arabic_metadata = extract_metadata(arabic_lines_full)
    vietnamese_metadata = extract_metadata(vietnamese_lines_full)

    arabic_verses = split_content(arabic_lines_full)
    vietnamese_verses = split_content(vietnamese_lines_full)

    surah_meta = fetch_json(SURA_METADATA_URL)

    output = build_output(arabic_verses, vietnamese_verses, surah_meta, arabic_metadata, vietnamese_metadata)

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {OUTPUT_PATH.relative_to(pathlib.Path.cwd())}")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # pylint: disable=broad-except
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)
