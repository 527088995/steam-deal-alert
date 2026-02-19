import 'package:flutter/material.dart';
import '../../models/game_model.dart';
import '../../screens/detail_screen.dart';

/// 详情页：大封面、价格、评论（详情内）、Banner
class DetailPage extends StatelessWidget {
  final String appId;
  final GameModel? initialGame;

  const DetailPage({super.key, required this.appId, this.initialGame});

  @override
  Widget build(BuildContext context) {
    return DetailScreen(appId: appId, initialGame: initialGame);
  }
}
