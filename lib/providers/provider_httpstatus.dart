import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

HTTPStatusModel httpStatusModel = HTTPStatusModel();

MyProvider providerHTTPStatus = MyProvider(
    name: "HTTPStatus",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'HTTP Status Codes',
      keywords: 'http status code response error web server api rest',
      action: () => httpStatusModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  httpStatusModel.init();
  Global.infoModel.addInfoWidget(
      "HTTPStatus",
      ChangeNotifierProvider.value(
          value: httpStatusModel,
          builder: (context, child) => HTTPStatusCard()),
      title: "HTTP Status Codes");
}

Future<void> _update() async {
  httpStatusModel.refresh();
}

enum HTTPStatusCategory {
  informational,
  success,
  redirect,
  clientError,
  serverError,
}

class HTTPStatusCode {
  final int code;
  final String name;
  final String description;
  final HTTPStatusCategory category;

  const HTTPStatusCode({
    required this.code,
    required this.name,
    required this.description,
    required this.category,
  });
}

const List<HTTPStatusCode> httpStatusCodes = [
  HTTPStatusCode(code: 100, name: 'Continue', description: 'The server has received the request headers and the client should proceed to send the request body.', category: HTTPStatusCategory.informational),
  HTTPStatusCode(code: 101, name: 'Switching Protocols', description: 'The server is switching protocols as requested by the client.', category: HTTPStatusCategory.informational),
  HTTPStatusCode(code: 102, name: 'Processing', description: 'The server has received and is processing the request, but no response is available yet.', category: HTTPStatusCategory.informational),
  HTTPStatusCode(code: 103, name: 'Early Hints', description: 'Used to return some response headers before final HTTP message.', category: HTTPStatusCategory.informational),
  HTTPStatusCode(code: 200, name: 'OK', description: 'The request has succeeded. The meaning of success depends on the HTTP method.', category: HTTPStatusCategory.success),
  HTTPStatusCode(code: 201, name: 'Created', description: 'The request has succeeded and a new resource has been created as a result.', category: HTTPStatusCategory.success),
  HTTPStatusCode(code: 202, name: 'Accepted', description: 'The request has been received but not yet acted upon.', category: HTTPStatusCategory.success),
  HTTPStatusCode(code: 203, name: 'Non-Authoritative Information', description: 'The request was successful but the information returned may be from another source.', category: HTTPStatusCategory.success),
  HTTPStatusCode(code: 204, name: 'No Content', description: 'The request was successful but there is no content to return.', category: HTTPStatusCategory.success),
  HTTPStatusCode(code: 205, name: 'Reset Content', description: 'The request was successful and the client should reset the document view.', category: HTTPStatusCategory.success),
  HTTPStatusCode(code: 206, name: 'Partial Content', description: 'The server is delivering only part of the resource due to a range header.', category: HTTPStatusCategory.success),
  HTTPStatusCode(code: 207, name: 'Multi-Status', description: 'The message body contains multiple status codes.', category: HTTPStatusCategory.success),
  HTTPStatusCode(code: 208, name: 'Already Reported', description: 'The members of a DAV binding have already been enumerated.', category: HTTPStatusCategory.success),
  HTTPStatusCode(code: 226, name: 'IM Used', description: 'The server has fulfilled a GET request for the resource.', category: HTTPStatusCategory.success),
  HTTPStatusCode(code: 300, name: 'Multiple Choices', description: 'The request has more than one possible response.', category: HTTPStatusCategory.redirect),
  HTTPStatusCode(code: 301, name: 'Moved Permanently', description: 'The URL of the requested resource has been changed permanently.', category: HTTPStatusCategory.redirect),
  HTTPStatusCode(code: 302, name: 'Found', description: 'The URL of the requested resource has been changed temporarily.', category: HTTPStatusCategory.redirect),
  HTTPStatusCode(code: 303, name: 'See Other', description: 'The server sent this response to direct the client to get the requested resource at another URI.', category: HTTPStatusCategory.redirect),
  HTTPStatusCode(code: 304, name: 'Not Modified', description: 'The resource has not been modified since the last request.', category: HTTPStatusCategory.redirect),
  HTTPStatusCode(code: 305, name: 'Use Proxy', description: 'A deprecated response indicating that the requested response must be accessed through a proxy.', category: HTTPStatusCategory.redirect),
  HTTPStatusCode(code: 306, name: 'Switch Proxy', description: 'Deprecated. No longer used.', category: HTTPStatusCategory.redirect),
  HTTPStatusCode(code: 307, name: 'Temporary Redirect', description: 'The request should be repeated with another URI, but future requests can still use the original URI.', category: HTTPStatusCategory.redirect),
  HTTPStatusCode(code: 308, name: 'Permanent Redirect', description: 'The request and all future requests should be repeated using another URI.', category: HTTPStatusCategory.redirect),
  HTTPStatusCode(code: 400, name: 'Bad Request', description: 'The server could not understand the request due to invalid syntax.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 401, name: 'Unauthorized', description: 'The client must authenticate itself to get the requested response.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 402, name: 'Payment Required', description: 'Access to the requested resource requires payment.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 403, name: 'Forbidden', description: 'The client does not have access rights to the content.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 404, name: 'Not Found', description: 'The server can not find the requested resource.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 405, name: 'Method Not Allowed', description: 'The request method is not supported by the server.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 406, name: 'Not Acceptable', description: 'The server cannot produce a response matching the list of acceptable values.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 407, name: 'Proxy Authentication Required', description: 'The client must first authenticate itself with the proxy.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 408, name: 'Request Timeout', description: 'The server timed out waiting for the request.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 409, name: 'Conflict', description: 'The request conflicts with the current state of the server.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 410, name: 'Gone', description: 'The requested content has been permanently deleted from server.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 411, name: 'Length Required', description: 'The Content-Length header field is required.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 412, name: 'Precondition Failed', description: 'One or more precondition fields in the request headers evaluated to false.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 413, name: 'Payload Too Large', description: 'The request body is larger than the server is willing to process.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 414, name: 'URI Too Long', description: 'The URL requested by the client is longer than the server is willing to interpret.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 415, name: 'Unsupported Media Type', description: 'The media type of the request body is not supported by the server.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 416, name: 'Range Not Satisfiable', description: 'The range specified by the Range header field cannot be satisfied.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 417, name: 'Expectation Failed', description: 'The expectation given in the Expect header field could not be met.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 418, name: 'I\'m a teapot', description: 'The server refuses the attempt to brew coffee with a teapot.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 421, name: 'Misdirected Request', description: 'The request was directed at a server that is not able to produce a response.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 422, name: 'Unprocessable Entity', description: 'The request was well-formed but was unable to be followed due to semantic errors.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 423, name: 'Locked', description: 'The resource being accessed is locked.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 424, name: 'Failed Dependency', description: 'The request failed because it depended on another request that failed.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 425, name: 'Too Early', description: 'The server is unwilling to risk processing a request that might be replayed.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 426, name: 'Upgrade Required', description: 'The client should switch to a different protocol.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 428, name: 'Precondition Required', description: 'The origin server requires the request to be conditional.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 429, name: 'Too Many Requests', description: 'The client has sent too many requests in a given amount of time.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 431, name: 'Request Header Fields Too Large', description: 'The request header fields are too large.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 451, name: 'Unavailable For Legal Reasons', description: 'The resource is unavailable for legal reasons.', category: HTTPStatusCategory.clientError),
  HTTPStatusCode(code: 500, name: 'Internal Server Error', description: 'The server encountered an unexpected condition that prevented it from fulfilling the request.', category: HTTPStatusCategory.serverError),
  HTTPStatusCode(code: 501, name: 'Not Implemented', description: 'The server does not support the request method.', category: HTTPStatusCategory.serverError),
  HTTPStatusCode(code: 502, name: 'Bad Gateway', description: 'The server received an invalid response from the upstream server.', category: HTTPStatusCategory.serverError),
  HTTPStatusCode(code: 503, name: 'Service Unavailable', description: 'The server is not ready to handle the request.', category: HTTPStatusCategory.serverError),
  HTTPStatusCode(code: 504, name: 'Gateway Timeout', description: 'The server is acting as a gateway and timed out.', category: HTTPStatusCategory.serverError),
  HTTPStatusCode(code: 505, name: 'HTTP Version Not Supported', description: 'The server does not support the HTTP version used in the request.', category: HTTPStatusCategory.serverError),
  HTTPStatusCode(code: 506, name: 'Variant Also Negotiates', description: 'Transparent content negotiation for the request results in a circular reference.', category: HTTPStatusCategory.serverError),
  HTTPStatusCode(code: 507, name: 'Insufficient Storage', description: 'The server is unable to store the representation needed to complete the request.', category: HTTPStatusCategory.serverError),
  HTTPStatusCode(code: 508, name: 'Loop Detected', description: 'The server detected an infinite loop while processing the request.', category: HTTPStatusCategory.serverError),
  HTTPStatusCode(code: 510, name: 'Not Extended', description: 'Further extensions to the request are required.', category: HTTPStatusCategory.serverError),
  HTTPStatusCode(code: 511, name: 'Network Authentication Required', description: 'The client needs to authenticate to gain network access.', category: HTTPStatusCategory.serverError),
];

String getHTTPStatusCategoryName(HTTPStatusCategory category) {
  switch (category) {
    case HTTPStatusCategory.informational:
      return 'Informational (1xx)';
    case HTTPStatusCategory.success:
      return 'Success (2xx)';
    case HTTPStatusCategory.redirect:
      return 'Redirect (3xx)';
    case HTTPStatusCategory.clientError:
      return 'Client Error (4xx)';
    case HTTPStatusCategory.serverError:
      return 'Server Error (5xx)';
  }
}

Color getHTTPStatusCategoryColor(HTTPStatusCategory category, ColorScheme colorScheme) {
  switch (category) {
    case HTTPStatusCategory.informational:
      return Color(0xFF90CAF9);
    case HTTPStatusCategory.success:
      return Color(0xFFA5D6A7);
    case HTTPStatusCategory.redirect:
      return Color(0xFFFFE082);
    case HTTPStatusCategory.clientError:
      return Color(0xFFEF9A9A);
    case HTTPStatusCategory.serverError:
      return Color(0xFFCE93D8);
  }
}

class HTTPStatusModel extends ChangeNotifier {
  bool _initialized = false;
  String _searchQuery = '';
  HTTPStatusCode? _selectedCode;
  HTTPStatusCategory? _selectedCategory;

  bool get initialized => _initialized;
  String get searchQuery => _searchQuery;
  HTTPStatusCode? get selectedCode => _selectedCode;
  HTTPStatusCategory? get selectedCategory => _selectedCategory;
  List<HTTPStatusCode> get allCodes => httpStatusCodes;

  List<HTTPStatusCode> get filteredCodes {
    var codes = httpStatusCodes;

    if (_selectedCategory != null) {
      codes = codes.where((c) => c.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      codes = codes.where((c) =>
        c.code.toString().contains(query) ||
        c.name.toLowerCase().contains(query) ||
        c.description.toLowerCase().contains(query)
      ).toList();
    }

    return codes;
  }

  void init() {
    if (!_initialized) {
      _initialized = true;
      Global.loggerModel.info("HTTPStatus initialized", source: "HTTPStatus");
      notifyListeners();
    }
  }

  void refresh() {
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCode(HTTPStatusCode? code) {
    _selectedCode = code;
    notifyListeners();
    if (code != null) {
      Global.loggerModel.info("HTTP Status selected: ${code.code}", source: "HTTPStatus");
    }
  }

  void setSelectedCategory(HTTPStatusCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void clearSelection() {
    _selectedCode = null;
    notifyListeners();
  }

  void copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class HTTPStatusCard extends StatefulWidget {
  @override
  State<HTTPStatusCard> createState() => _HTTPStatusCardState();
}

class _HTTPStatusCardState extends State<HTTPStatusCard> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<HTTPStatusModel>();

    if (!model.initialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.http, color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: 8),
                  Text('HTTP Status Codes', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              SizedBox(height: 12),
              _buildSearchField(context, model),
              SizedBox(height: 8),
              _buildCategoryFilter(context, model),
              SizedBox(height: 12),
              if (model.selectedCode != null)
                _buildCodeDetail(context, model)
              else
                _buildCodeList(context, model),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, HTTPStatusModel model) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search codes (number, name, description)',
        prefixIcon: Icon(Icons.search, size: 20),
        suffixIcon: _searchController.text.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.clear, size: 18),
              onPressed: () {
                _searchController.clear();
                model.setSearchQuery('');
              },
            )
          : null,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => model.setSearchQuery(value),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, HTTPStatusModel model) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ActionChip(
            label: Text('All'),
            onPressed: () => model.setSelectedCategory(null),
            backgroundColor: model.selectedCategory == null
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          ),
          SizedBox(width: 4),
          ...HTTPStatusCategory.values.map((category) => Padding(
            padding: EdgeInsets.only(left: 4),
            child: ActionChip(
              label: Text('${category.index + 1}xx'),
              onPressed: () => model.setSelectedCategory(category),
              backgroundColor: model.selectedCategory == category
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCodeList(BuildContext context, HTTPStatusModel model) {
    final codes = model.filteredCodes;

    if (codes.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text('No status codes found', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }

    return Column(
      children: codes.take(20).map((code) => _buildCodeTile(context, model, code)).toList(),
    );
  }

  Widget _buildCodeTile(BuildContext context, HTTPStatusModel model, HTTPStatusCode code) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = getHTTPStatusCategoryColor(code.category, colorScheme);

    return ListTile(
      onTap: () => model.setSelectedCode(code),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: categoryColor.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          code.code.toString(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
      ),
      title: Text(code.name),
      subtitle: Text(
        code.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
      isThreeLine: false,
      dense: true,
    );
  }

  Widget _buildCodeDetail(BuildContext context, HTTPStatusModel model) {
    final code = model.selectedCode!;
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = getHTTPStatusCategoryColor(code.category, colorScheme);

    return Card(
      color: categoryColor.withValues(alpha: 0.3),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        code.code.toString(),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(code.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(getHTTPStatusCategoryName(code.category), style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => model.clearSelection(),
                  tooltip: 'Close detail',
                ),
              ],
            ),
            SizedBox(height: 12),
            Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            SizedBox(height: 4),
            SelectableText(
              code.description,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    final text = '${code.code} ${code.name}\n${code.description}';
                    model.copyToClipboard(text, context);
                  },
                  child: Text('Copy Info'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}