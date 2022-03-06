// import 'package:catex/catex.dart';
import 'package:flutter/widgets.dart';

class CatexExample extends StatelessWidget {
  const CatexExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, i) => const Center(
        // child: CaTeX(
        //   '\\sqrt[$i]{a^2 + b^2} = ' * 5,
        // ),
        child: Text('Not NNBD'),
      ),
    );
  }
}
