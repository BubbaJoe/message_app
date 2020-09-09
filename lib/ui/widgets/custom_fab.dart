import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CustomFAB extends StatefulWidget {
  final _controller;

  const CustomFAB({Key key, controller})
      : _controller = controller,
        super(key: key);

  @override
  _CustomFABState createState() => _CustomFABState();
}

class _CustomFABState extends State<CustomFAB> with TickerProviderStateMixin{
  bool expandFAB = false;

  void _switchFAB(bool expand) {
    setState(() {
      expandFAB = expand;
    });
  }

  @override
  void initState() {
    super.initState();
    widget._controller
      ..addListener(() {
        if (widget._controller.position.userScrollDirection ==
            ScrollDirection.reverse) {
          _switchFAB(false);
        } else if (widget._controller.position.userScrollDirection ==
            ScrollDirection.forward) {
          _switchFAB(true);
        }
      });
  }

  @override
  void dispose() {
    widget._controller.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        isExtended: expandFAB,
        onPressed: () {},
        label: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Icon(
                    Icons.message,
                    color: Colors.white,
                    size: 23,
                  ),
                  if (expandFAB) SizedBox(width: 8),
                  AnimatedSize(
                    vsync: this,
                    duration: Duration(milliseconds: 200),
                    child: Text(
                    expandFAB ? "Start chat" : "",
                      style: TextStyle(fontSize: 17, color: Colors.white,
                        fontWeight: FontWeight.w400,
                        height: 1
                      ),
                    ),
                  ),
                ],
              )
      ),
    );
  }
}
