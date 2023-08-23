import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pagination_componentn/pagination_components/paginated_list_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primaryColor: Colors.blue),
      home: const PaginationScreen(),
    );
  }
}

class PaginationScreen extends StatefulWidget {
  const PaginationScreen({super.key});

  @override
  State<PaginationScreen> createState() => _PaginationScreenState();
}

class _PaginationScreenState extends State<PaginationScreen> {
  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<List<PostModel>> loadData({int pageNumber = 1, maxRows = 10}) async {
    final data = await Dio().get('https://jsonplaceholder.typicode.com/posts',
        queryParameters: {'_page': pageNumber, '_limit': maxRows});
    return (data.data as List).map((e) => PostModel.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PaginatedListView<PostModel>(
      itemBuilder: (context, index, post) {
        return ListTile(
          title: Text(
            'index: $index ${post.title}',
            style: const TextStyle(color: Colors.black),
          ),
          subtitle: Text(post.body),
        );
      },
      onEmpty: const Text('List is Empty'),
      initialLoader: const CircularProgressIndicator(color: Colors.red),
      bottomLoader: const CircularProgressIndicator(color: Colors.yellow),
      maxRows: 15,
      onPageChanged: (pageNumber, maxRows) async =>
          await loadData(pageNumber: pageNumber, maxRows: maxRows),
    ));
  }
}

class PostModel {
  final int userId;
  final int id;
  final String title;
  final String body;

  PostModel({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        userId: json["userId"],
        id: json["id"],
        title: json["title"],
        body: json["body"],
      );

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "id": id,
        "title": title,
        "body": body,
      };
}

   // onError: (pageNumber, maxRows) {
      //   return TextButton(
      //     child: const Text(
      //       'Try Again',
      //     ),
      //     onPressed: () {
      //       loadData(pageNumber: pageNumber, maxRows: maxRows);
      //     },
      //   );
      // },