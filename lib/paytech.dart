library paytech;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

const MOBILE_CANCEL_URL = "https://paytech.sn/mobile/cancel";
const MOBILE_SUCCESS_URL = "https://paytech.sn/mobile/success";

class PayTech extends StatefulWidget {
  final String paymentUrl;
  final String appBarTitle;
  final bool centerTitle;
  final Color appBarBgColor;
  final TextStyle appBarTextStyle;
  final IconData backButtonIcon;
  final bool hideAppBar;

  PayTech(this.paymentUrl,
      {this.hideAppBar = false,
      this.backButtonIcon = Icons.arrow_back_ios,
      this.appBarTitle = "PayTech",
      this.centerTitle = true,
      this.appBarBgColor = const Color(0xFF1b7b80),
      this.appBarTextStyle = const TextStyle()});

  @override
  _PayTechState createState() => _PayTechState();
}

class _PayTechState extends State<PayTech> {
  final GlobalKey webViewKey = GlobalKey();
  // InAppWebViewController? webViewController;
  // // late InAppWebViewGroupOptions options;
  // late InAppWebViewSettings settings;

  late final PlatformWebViewControllerCreationParams params;
  late WebViewController controller;

  bool onClosing = false;

  void gotoFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void initState() {
    super.initState();
    initWebView();

    if (widget.hideAppBar) {
      gotoFullscreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    /*if(widget.hideAppBar){
      WidgetsFlutterBinding.ensureInitialized();
      SystemChrome.setEnabledSystemUIOverlays([]);
    }*/

    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: new Text(
                widget.appBarTitle,
                style: widget.appBarTextStyle,
              ),
              backgroundColor: widget.appBarBgColor,
              //backgroundColor: APP_PRIMARY_COLOR,
              centerTitle: widget.centerTitle,
              leading: IconButton(
                icon: Icon(widget.backButtonIcon, color: Colors.white),
                onPressed: () {
                  _close(false);
                },
              ),
            ),

      body: WebViewWidget(
        controller: controller,
      ),
      // body: Container(
      //   child: InAppWebView(
      //     key: webViewKey,
      //     initialUrlRequest: URLRequest(url: WebUri(widget.paymentUrl)),
      //     initialSettings: settings,
      //     onWebViewCreated: (controller) {
      //       webViewController = controller;
      //       onWebViewCreated(controller);
      //     },
      //     onLoadStart: (controller, url) {
      //       this.onLoadStart(controller, url?.toString() ?? '');
      //     },
      //     // androidOnPermissionRequest: (controller, origin, resources) async {
      //     //   return PermissionRequestResponse(
      //     //       resources: resources,
      //     //       action: PermissionRequestResponseAction.GRANT);
      //     // },
      //     onPermissionRequest: (controller, permissionRequest) async {
      //       return PermissionResponse(
      //           resources: permissionRequest.resources,
      //           action: PermissionResponseAction.GRANT);
      //     },
      //     shouldOverrideUrlLoading: (controller, navigationAction) async {
      //       //var uri = navigationAction.request.url;
      //       return NavigationActionPolicy.ALLOW;
      //     },
      //     onLoadStop: (controller, url) async {
      //       this.onLoadStop(controller, url?.toString() ?? '');
      //     },
      //     onConsoleMessage: (controller, consoleMessage) {
      //       print(consoleMessage);
      //     },
      //   ),
      // ),
    );
  }

  void initWebView() {
    controller = WebViewController()
      ..addJavaScriptChannel(
        'FlutterChanelOpenUrl',
        onMessageReceived: (args) {
          String url = args.toString();
          print("FlutterChanelOpenUrl Call");
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
      )
      ..addJavaScriptChannel(
        'FlutterChanelOpenDial',
        onMessageReceived: (args) {
          String phone = args.toString();
          print("FlutterChanelOpenDial Call");
          String encodedPhone = Uri.encodeComponent(phone);
          Uri phoneUri = Uri(scheme: 'tel', path: encodedPhone);
          launchUrl(phoneUri, mode: LaunchMode.externalApplication);
        },
      )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint("LOADER ::: $progress");
            // const LoaderWidget();
          },
          onPageStarted: (String url) {
            if (url.contains(MOBILE_SUCCESS_URL) ||
                url.contains(MOBILE_CANCEL_URL)) {
              bool result = url.contains("success") ? true : false;
              _close(result);
            }
          },
          onPageFinished: (String url) {
            if (url.contains(MOBILE_SUCCESS_URL) ||
                url.contains(MOBILE_CANCEL_URL)) {
              bool result = url.contains("success") ? true : false;
              _close(result);
            }
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));

    // settings = InAppWebViewSettings(
    //   useShouldOverrideUrlLoading: true,
    //   mediaPlaybackRequiresUserGesture: false,
    //   useHybridComposition: true,
    //   allowsInlineMediaPlayback: true,
    //   javaScriptEnabled: true,
    //   allowUniversalAccessFromFileURLs: true,
    //   allowFileAccessFromFileURLs: true,
    //   javaScriptCanOpenWindowsAutomatically: true,
    //   loadWithOverviewMode: false,
    //   useWideViewPort: false,
    //   enableViewportScale: true,
    // );

    // options = InAppWebViewGroupOptions(
    //   crossPlatform: InAppWebViewOptions(
    //     useShouldOverrideUrlLoading: true,
    //     mediaPlaybackRequiresUserGesture: false,
    //     javaScriptEnabled: true,
    //     allowUniversalAccessFromFileURLs: true,
    //     allowFileAccessFromFileURLs: true,
    //     javaScriptCanOpenWindowsAutomatically: true,
    //   ),
    //   android: AndroidInAppWebViewOptions(
    //     useHybridComposition: true,
    //     loadWithOverviewMode: false,
    //     useWideViewPort: false,
    //   ),
    //   ios: IOSInAppWebViewOptions(
    //     allowsInlineMediaPlayback: true,
    //     enableViewportScale: true,
    //   ),
    // );
  }

  void _close(bool success) async {
    if (!onClosing) {
      onClosing = true;
      //webViewController.close();
      Navigator.of(context).pop(success);

      if (widget.hideAppBar) {
        exitFullscreen();
      }
    }
  }

  // void onLoadStop(InAppWebViewController controller, String url) {
  //   if (url.contains(MOBILE_SUCCESS_URL) || url.contains(MOBILE_CANCEL_URL)) {
  //     bool result = url.contains("success") ? true : false;
  //     _close(result);
  //   }
  // }

  // void onLoadStart(InAppWebViewController controller, String url) {
  //   if (url.contains(MOBILE_SUCCESS_URL) || url.contains(MOBILE_CANCEL_URL)) {
  //     bool result = url.contains("success") ? true : false;
  //     _close(result);
  //   }
  // }

  // void onWebViewCreated(InAppWebViewController controller) {
  //   controller.addJavaScriptHandler(
  //       handlerName: 'FlutterChanelOpenUrl',
  //       callback: (args) {
  //         String url = args[0].toString();
  //         print("FlutterChanelOpenUrl Call");
  //         launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  //       });

  //   controller.addJavaScriptHandler(
  //       handlerName: 'FlutterChanelOpenDial',
  //       callback: (args) {
  //         String phone = args[0].toString();
  //         print("FlutterChanelOpenDial Call");
  //         String encodedPhone = Uri.encodeComponent(phone);
  //         Uri phoneUri = Uri(scheme: 'tel', path: encodedPhone);
  //         launchUrl(phoneUri, mode: LaunchMode.externalApplication);
  //       });
  // }
}
