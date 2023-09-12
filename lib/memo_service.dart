import 'dart:convert';
import 'package:flutter/material.dart';
import 'main.dart';

class Memo {
  Memo({
    required this.content,
    this.isPinned = false,
  });

  String content;
  bool isPinned;

  //map 자료형으로 바꿔주는 toJson함수
  Map toJson() {
    return {
      'content': content,
      'isPinned': isPinned,
    };
  }

  //다시 Memo 객체를 복원하는 함수 fronJson
  factory Memo.fromJson(json) {
    return Memo(
      content: json['content'],
      isPinned: json['isPinned'] ?? false,
    );
  }
}

// Memo 데이터는 모두 여기서 관리
class MemoService extends ChangeNotifier {
  //ChangeNotifier는 memoList가 변경되는 경우 해당 값을 보여주는 화면들을 갱신시켜 주는 기능을 구현
  MemoService() {
    //MemoService 를 시작할 때, 저장된 메모를 불러와서 memoList 변수에 담음
    loadMemoList();
  }

  List<Memo> memoList = [
    // Memo(content: '장보기 목록: 사과, 양파'), // 더미(dummy) 데이터
    // Memo(content: '새 메모'), // 더미(dummy) 데이터
  ];

  createMemo({required String content}) {
    //string 자료형의 content 변수를 받아 Memo 생성하고 이를 memoList 맨 뒤에 추가하는 방식
    Memo memo = Memo(content: content);
    memoList.add(memo);

    notifyListeners(); // Consumer<MemoService>의 builder 부분을 호출해서 화면 새로고침
    saveMemoList();
  }

  updateMemo({required int index, required String content}) {
    Memo memo = memoList[index];
    memo.content = content;
    notifyListeners();
    saveMemoList();
  }

  updatePinMemo({required int index}) {
    Memo memo = memoList[index];
    memo.isPinned = !memo.isPinned;
    memoList = [
      ...memoList.where((element) => element.isPinned),
      ...memoList.where((element) => !element.isPinned)
    ];
    notifyListeners();
    saveMemoList();
  }

  deleteMemo({required int index}) {
    memoList.removeAt(index);
    notifyListeners();
    saveMemoList();
  }

  saveMemoList() {
    //List<Memo> ⇒ (toJson) ⇒  List<Map> ⇒ (jsonEncode) ⇒  String
    List memoJsonList = memoList.map((memo) => memo.toJson()).toList();

    String jsonString = jsonEncode(memoJsonList);

    prefs.setString('memoList', jsonString);
  }

  loadMemoList() {
    //String ⇒ (jsonDecode) ⇒ List<Map> ⇒ (fromJson) ⇒ List<Memo>
    String? jsonString = prefs.getString('memoList');

    if (jsonString == null) return; //null이면 로드하지 않음

    List memoJsonList = jsonDecode(jsonString);

    memoList = memoJsonList.map((json) => Memo.fromJson(json)).toList();
  }
}
