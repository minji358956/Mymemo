import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mymemo/memo_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences prefs; //전역 변수 prefs 선언

void main() async {
  //저장된 파일을 읽는데 시간이 걸리므로 완료될 때까지 기다리도록 await
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();

  runApp(
    //MultiProvider로 MyApp을 감싸서 모든 위젯들의 최상단에 provider들을 등록해줌
    //MultiProvider는 위젯트리 꼭대기에 여러 Service들을 등록할 수 있도록 만들 때 사용함
    MultiProvider(
      providers: [
        //MemoService는 memoList 값이 변하는 경우 HomePage에 변경사항을 알려주도록 구현해야 하므로 ChangeNotifierProvider로 Provider에 등록해줌
        ChangeNotifierProvider(create: (context) => MemoService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

// 홈 페이지
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    /* MemoService에서 값이 변경되는 경우, StatefulWidget의 setState와 같이 notifyListeners();를 호출하는데, 이 때 해당 서비스의 Consumer로 등록된 모든 위젯의 builder 함수가 재호출 되면서 화면이 갱신됨. */
    return Consumer<MemoService>(
      //위젯 트리를 타고 올라가 Provider로 등록된 MemoService를 찾음
      builder: (context, memoService, child) {
        //화면에 보여줄 위젯을 반환하는 함수로, 위젯트리 상단에서 찾아온 클래스를 두 번째 파라미터로 받을 수 있음
        List<Memo> memoList = memoService.memoList; //memoSerive로부터 memoList 가져옴

        return Scaffold(
          appBar: AppBar(
            title: Text("mymemo"),
            centerTitle: true,
            backgroundColor: Color(0xFFFFA3D7),
          ),
          body: memoList.isEmpty
              ? Center(child: Text("메모를 작성해주세요"))
              : ListView.builder(
                  itemCount: memoList.length, //memoList 개수 만큼 보여줌
                  itemBuilder: (context, index) {
                    Memo memo = memoList[index]; //index에 해당하는 memo 가져옴

                    return ListTile(
                      //박스 안에 여러 영역에 다른 위젯을 손쉽게 배치 가능
                      //메모 고정 아이콘
                      leading: IconButton(
                        //선두에 아이콘 배치
                        icon: Icon(memo.isPinned
                            ? CupertinoIcons.pin_fill
                            : CupertinoIcons.pin), //isPinned이 true면 핀이 칠해지도록
                        onPressed: () {
                          memoService.updatePinMemo(index: index);
                        },
                      ),
                      title: Text(
                        memo.content,
                        maxLines: 3, //최대 3줄까지만 보여줌
                        overflow: TextOverflow
                            .ellipsis, //지정 사이즈를 넘을 때 글자 뒤에 ...을 붙여 생략
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailPage(
                              index: index,
                            ),
                          ),
                        );
                        if (memo.content.isEmpty) {
                          //메모가 비어있으면
                          memoService.deleteMemo(index: index); //삭제
                        }
                      },
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            backgroundColor: Color(0xFFFFA3D7),
            onPressed: () async {
              memoService.createMemo(content: ''); //비어있는 메모가 추가됨
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailPage(
                    index: memoService.memoList.length -
                        1, //memoList 맨 뒤에 추가됐으므로 -1 인덱스
                  ),
                ),
              );
              if (memoList[memoService.memoList.length - 1].content.isEmpty) {
                memoService.deleteMemo(index: memoList.length - 1);
              }
            },
          ),
        );
      },
    );
  }
}

// 메모 생성 및 수정 페이지
class DetailPage extends StatelessWidget {
  DetailPage({super.key, required this.index});

  final int index;

  //TextField에 입력된 값을 가지고 오거나 TextField에 입력된 값이 변경될 때 사용
  TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    MemoService memoService =
        context.read<MemoService>(); //위젯 트리 상단에 있는 Provider로 등록한 클래스에 접근
    Memo memo = memoService.memoList[index];

    contentController.text = memo.content;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              showDeleteDialog(context, memoService);
            },
            icon: Icon(Icons.delete),
          )
        ],
        backgroundColor: Color(0xFFFFA3D7),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: contentController, //변수 내용을 보여줄 거임
          decoration: InputDecoration(
            hintText: "메모를 입력하세요",
            border: InputBorder.none,
          ),
          autofocus: true,
          maxLines: null,
          expands: true,
          keyboardType: TextInputType.multiline,
          onChanged: (value) {
            memoService.updateMemo(index: index, content: value);
          },
        ),
      ),
    );
  }

  Future<dynamic> showDeleteDialog(
      BuildContext context, MemoService memoService) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("정말 삭제하시겠습니까?"),
          actions: [
            //배열로 원하는 위젯 삽입 가능
            TextButton(
              onPressed: () {
                memoService.deleteMemo(index: index);
                Navigator.pop(context); //팝업 닫기(현재 페이지를 스택에서 제거)
                Navigator.pop(context); //HomePage로 이동
              },
              child: Text(
                "확인",
                style: TextStyle(color: Colors.pink),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("취소"),
            ),
          ],
        );
      },
    );
  }
}
