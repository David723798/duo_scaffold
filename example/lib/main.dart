import 'dart:ui';

import 'package:duo_scaffold/duo_scaffold.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MailDemoApp());

/// An interactive reference implementation for `duo_scaffold`.
class MailDemoApp extends StatelessWidget {
  const MailDemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Duo Mail',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: const MailDemoPage(),
  );
}

class MailDemoPage extends StatefulWidget {
  const MailDemoPage({super.key});

  @override
  State<MailDemoPage> createState() => _MailDemoPageState();
}

class _MailDemoPageState extends State<MailDemoPage> {
  final List<_Message> _messages = const <_Message>[
    _Message(
      'maya',
      'inbox',
      'Maya Chen',
      'Launch notes',
      'The fold-aware preview is ready for review.',
      '9:41',
    ),
    _Message(
      'samir',
      'starred',
      'Samir Patel',
      'Design handoff',
      'I added the wide and tabletop states to the prototype.',
      'Yesterday',
    ),
    _Message(
      'duo',
      'sent',
      'Duo team',
      'Weekly update',
      'The next build includes state-preserving panes.',
      'Mon',
    ),
  ];
  String? _selectedMessageId;
  bool _isShowingInbox = true;
  int _selectedDestination = 0;
  DuoLayout? _previewLayout;
  DuoChromeLayout? _chromeLayout;

  Iterable<DuoDisplayFeature> _previewFeatures(DuoLayout layout) {
    switch (layout) {
      case DuoLayout.book:
        return const <DuoDisplayFeature>[
          DuoDisplayFeature(
            bounds: Rect.fromLTWH(398, 0, 4, 1000),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ];
      case DuoLayout.tabletop:
        return const <DuoDisplayFeature>[
          DuoDisplayFeature(
            bounds: Rect.fromLTWH(0, 348, 1000, 4),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ];
      default:
        return const <DuoDisplayFeature>[];
    }
  }

  static const List<String> _destinationIds = <String>[
    'inbox',
    'starred',
    'sent',
  ];

  List<_Message> get _visibleMessages => _messages
      .where(
        ((_Message message) =>
            message.mailbox == _destinationIds[_selectedDestination]),
      )
      .toList(growable: false);

  _Message? get _selectedMessage {
    for (final _Message message in _visibleMessages) {
      if (message.id == _selectedMessageId) return message;
    }
    return _visibleMessages.isEmpty ? null : _visibleMessages.first;
  }

  void _selectMessage(String id) => setState(() {
    _selectedMessageId = id;
    _isShowingInbox = false;
  });

  void _showInbox() => setState(() => _isShowingInbox = true);

  void _selectDestination(String id) => setState(() {
    _selectedDestination = _destinationIds.indexOf(id);
    _isShowingInbox = true;
  });

  Future<void> _compose(BuildContext context) async {
    final bool? sent = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute<bool>(builder: (_) => const ComposePage()));
    if (!context.mounted || sent != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Message sent.')));
  }

  @override
  Widget build(BuildContext context) {
    final DuoLayoutPolicy policy = DuoLayoutPolicy(
      layoutOverride: _previewLayout,
    );
    final DuoChromePolicy chromePolicy = DuoChromePolicy(
      layoutOverride: _chromeLayout,
    );
    return DuoScaffold(
      appBar: AppBar(
        title: const Text('Duo Mail'),
        actions: <Widget>[
          _LayoutMenu(
            onChanged: (DuoLayout? value) {
              setState(() => _previewLayout = value);
            },
          ),
          _ChromeLayoutMenu(
            value: _chromeLayout,
            onChanged: (DuoChromeLayout? value) {
              setState(() => _chromeLayout = value);
            },
          ),
        ],
      ),
      drawer: _MailDrawer(onDestinationSelected: _selectDestination),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _compose(context),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Compose'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedDestination,
        onDestinationSelected: (int value) {
          _selectDestination(_destinationIds[value]);
        },
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: 'Starred',
          ),
          NavigationDestination(
            icon: Icon(Icons.send_outlined),
            selectedIcon: Icon(Icons.send),
            label: 'Sent',
          ),
        ],
      ),
      policy: chromePolicy,
      actions: <DuoAction>[
        DuoAction(
          id: 'preview-layout',
          label: 'Preview layout',
          icon: const Icon(Icons.preview_outlined),
          onPressed: null,
          visibilityPriority: 1,
          sideBuilder: (BuildContext context) => _LayoutMenu(
            onChanged: (DuoLayout? value) {
              setState(() => _previewLayout = value);
            },
          ),
        ),
        DuoAction(
          id: 'preview-controls',
          label: 'Preview controls layout',
          icon: const Icon(Icons.vertical_split_outlined),
          onPressed: null,
          sideBuilder: (BuildContext context) => _ChromeLayoutMenu(
            value: _chromeLayout,
            onChanged: (DuoChromeLayout? value) {
              setState(() => _chromeLayout = value);
            },
          ),
        ),
      ],
      footerActions: <DuoAction>[
        DuoAction(
          id: 'compose',
          label: 'Compose',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _compose(context),
          visibilityPriority: 1,
        ),
      ],
      destinations: const <DuoDestination>[
        DuoDestination(
          id: 'inbox',
          label: 'Inbox',
          icon: Icon(Icons.inbox_outlined),
          selectedIcon: Icon(Icons.inbox),
        ),
        DuoDestination(
          id: 'starred',
          label: 'Starred',
          icon: Icon(Icons.star_outline),
          selectedIcon: Icon(Icons.star),
        ),
        DuoDestination(
          id: 'sent',
          label: 'Sent',
          icon: Icon(Icons.send_outlined),
          selectedIcon: Icon(Icons.send),
        ),
      ],
      selectedDestinationId: _destinationIds[_selectedDestination],
      onDestinationSelected: _selectDestination,
      bodyBuilder: (BuildContext context, DuoChromeInfo chromeInfo) {
        final DuoLayoutInfo layout = policy.resolve(
          chromeInfo.contentSize,
          displayFeatures: _previewLayout == null
              ? MediaQuery.displayFeaturesOf(
                  context,
                ).map(DuoDisplayFeature.fromDisplayFeature)
              : _previewFeatures(_previewLayout!),
        );
        return Column(
          children: <Widget>[
            _LayoutStatus(
              layout: layout,
              previewing: _previewLayout != null,
              chromeLayout: chromeInfo.layout,
            ),
            Expanded(
              child: _MailBody(
                layout: layout,
                messages: _visibleMessages,
                selectedMessage: _selectedMessage,
                showInbox: _isShowingInbox,
                onSelect: _selectMessage,
                onBack: _showInbox,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A separate route that demonstrates using [DuoScaffold] inside a pushed page.
class ComposePage extends StatelessWidget {
  const ComposePage({super.key});

  void _close(BuildContext context) => Navigator.of(context).pop();

  void _send(BuildContext context) => Navigator.of(context).pop(true);

  @override
  Widget build(BuildContext context) => DuoScaffold(
    appBar: AppBar(
      title: const Text('New message'),
      leading: IconButton(
        tooltip: 'Discard draft',
        onPressed: () => _close(context),
        icon: const Icon(Icons.close),
      ),
    ),
    leadingAction: DuoAction(
      id: 'discard-draft',
      label: 'Discard draft',
      icon: const Icon(Icons.close),
      onPressed: () => _close(context),
    ),
    actions: <DuoAction>[
      DuoAction(
        id: 'send',
        label: 'Send',
        icon: const Icon(Icons.send),
        onPressed: () => _send(context),
      ),
    ],
    bodyBuilder: (BuildContext context, DuoChromeInfo chromeInfo) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'New message',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          const TextField(
            decoration: InputDecoration(labelText: 'To'),
            autofocus: true,
          ),
          const TextField(decoration: InputDecoration(labelText: 'Subject')),
          const SizedBox(height: 16),
          const Expanded(
            child: TextField(
              expands: true,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                labelText: 'Message',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _send(context),
            icon: const Icon(Icons.send),
            label: const Text('Send'),
          ),
        ],
      ),
    ),
  );
}

class _MailBody extends StatelessWidget {
  const _MailBody({
    required this.layout,
    required this.messages,
    required this.selectedMessage,
    required this.showInbox,
    required this.onSelect,
    required this.onBack,
  });

  final DuoLayoutInfo layout;
  final List<_Message> messages;
  final _Message? selectedMessage;
  final bool showInbox;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final bool hasDetail = selectedMessage != null;
    return PopScope(
      canPop: showInbox || layout.hasTwoPanes,
      // ignore: deprecated_member_use
      onPopInvoked: (bool didPop) {
        if (!didPop) onBack();
      },
      child: DuoBody(
        layout: layout,
        compactPane: showInbox || !hasDetail
            ? DuoPane.primary
            : DuoPane.secondary,
        primary: _InboxPane(
          messages: messages,
          selectedMessageId: selectedMessage?.id,
          onSelect: onSelect,
        ),
        secondary: _MessagePane(
          message: selectedMessage,
          onBack: onBack,
          showBack: !layout.hasTwoPanes,
        ),
        tabletopTop: _MessagePane(
          message: selectedMessage,
          onBack: onBack,
          compact: true,
          showBack: false,
        ),
        tabletopBottom: selectedMessage == null
            ? const _EmptyMessagePane()
            : _AttachmentPane(message: selectedMessage!),
      ),
    );
  }
}

class _InboxPane extends StatelessWidget {
  const _InboxPane({
    required this.messages,
    required this.selectedMessageId,
    required this.onSelect,
  });

  final List<_Message> messages;
  final String? selectedMessageId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLowest,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final _Message message = messages[index];
        return ListTile(
          selected: message.id == selectedMessageId,
          leading: CircleAvatar(child: Text(message.sender[0])),
          title: Text(message.sender),
          subtitle: Text(
            '${message.subject} — ${message.preview}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(message.time),
          onTap: () => onSelect(message.id),
        );
      },
    ),
  );
}

class _MessagePane extends StatelessWidget {
  const _MessagePane({
    this.message,
    required this.onBack,
    this.compact = false,
    this.showBack = true,
  });

  final _Message? message;
  final VoidCallback onBack;
  final bool compact;
  final bool showBack;

  @override
  Widget build(BuildContext context) => Material(
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        if (showBack && !compact)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Inbox'),
            ),
          ),
        Text(
          message?.subject ?? 'Select a message',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Text(
          message == null
              ? 'Choose a message from the list.'
              : 'From ${message!.sender} · ${message!.time}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const Divider(height: 32),
        Text(
          message == null
              ? 'The current destination has no selected message.'
              : '${message!.preview}\n\nThis sample keeps the selected message in the page state, so it remains selected as the layout changes.',
        ),
      ],
    ),
  );
}

class _EmptyMessagePane extends StatelessWidget {
  const _EmptyMessagePane();

  @override
  Widget build(BuildContext context) => const _MessagePane(onBack: _noop);
}

void _noop() {}

class _AttachmentPane extends StatelessWidget {
  const _AttachmentPane({required this.message});

  final _Message message;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.attach_file_outlined, size: 42),
          const SizedBox(height: 8),
          Text('Attachments for ${message.subject}'),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () {},
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download preview'),
          ),
        ],
      ),
    ),
  );
}

class _LayoutStatus extends StatelessWidget {
  const _LayoutStatus({
    required this.layout,
    required this.previewing,
    required this.chromeLayout,
  });

  final DuoLayoutInfo layout;
  final bool previewing;
  final DuoChromeLayout chromeLayout;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Text(
      '${_layoutLabel(layout.layout)} · ${_chromeLayoutLabel(chromeLayout)} controls · ${layout.size.width.round()} × ${layout.size.height.round()}${previewing ? ' · simulated' : ''}',
      style: Theme.of(context).textTheme.labelMedium,
    ),
  );
}

class _ChromeLayoutMenu extends StatelessWidget {
  const _ChromeLayoutMenu({required this.value, required this.onChanged});

  final DuoChromeLayout? value;
  final ValueChanged<DuoChromeLayout?> onChanged;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_ChromePreview>(
    tooltip: 'Preview controls layout',
    icon: const Icon(Icons.vertical_split_outlined),
    initialValue: _ChromePreview.fromLayout(value),
    onSelected: (_ChromePreview preview) => onChanged(preview.layout),
    itemBuilder: (BuildContext context) => _ChromePreview.values
        .map(
          (_ChromePreview preview) => PopupMenuItem<_ChromePreview>(
            value: preview,
            child: Text(preview.label),
          ),
        )
        .toList(growable: false),
  );
}

enum _ChromePreview {
  automatic(null, 'Automatic'),
  topAndBottom(DuoChromeLayout.topAndBottom, 'Top and bottom'),
  leftRail(DuoChromeLayout.leftRail, 'Left rail'),
  rightRail(DuoChromeLayout.rightRail, 'Right rail');

  const _ChromePreview(this.layout, this.label);

  final DuoChromeLayout? layout;
  final String label;

  static _ChromePreview fromLayout(DuoChromeLayout? layout) => _ChromePreview
      .values
      .firstWhere((_ChromePreview preview) => preview.layout == layout);
}

enum _LayoutPreview {
  automatic,
  compactPortrait,
  compactLandscape,
  expandedLandscape,
  expandedPortrait,
  book,
  tabletop,
}

class _LayoutMenu extends StatelessWidget {
  const _LayoutMenu({required this.onChanged});

  final ValueChanged<DuoLayout?> onChanged;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_LayoutPreview>(
    tooltip: 'Preview layout',
    icon: const Icon(Icons.preview_outlined),
    onSelected: (_LayoutPreview preview) => onChanged(switch (preview) {
      _LayoutPreview.automatic => null,
      _LayoutPreview.compactPortrait => DuoLayout.compactPortrait,
      _LayoutPreview.compactLandscape => DuoLayout.compactLandscape,
      _LayoutPreview.expandedLandscape => DuoLayout.expandedLandscape,
      _LayoutPreview.expandedPortrait => DuoLayout.expandedPortrait,
      _LayoutPreview.book => DuoLayout.book,
      _LayoutPreview.tabletop => DuoLayout.tabletop,
    }),
    itemBuilder: (BuildContext context) => <PopupMenuEntry<_LayoutPreview>>[
      const PopupMenuItem<_LayoutPreview>(
        value: _LayoutPreview.automatic,
        child: Text('Automatic'),
      ),
      ...DuoLayout.values.map(
        (DuoLayout layout) => PopupMenuItem<_LayoutPreview>(
          value: _LayoutPreview.values[layout.index + 1],
          child: Text(_layoutLabel(layout)),
        ),
      ),
    ],
  );
}

class _MailDrawer extends StatelessWidget {
  const _MailDrawer({required this.onDestinationSelected});

  final ValueChanged<String> onDestinationSelected;

  @override
  Widget build(BuildContext context) => Drawer(
    child: Column(
      children: <Widget>[
        const DrawerHeader(
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text('Duo Mail', style: TextStyle(fontSize: 24)),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.inbox_outlined),
          title: const Text('Inbox'),
          onTap: () {
            onDestinationSelected('inbox');
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.send_outlined),
          title: const Text('Sent'),
          onTap: () {
            onDestinationSelected('sent');
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

String _layoutLabel(DuoLayout layout) => switch (layout) {
  DuoLayout.compactPortrait => 'Compact portrait',
  DuoLayout.compactLandscape => 'Compact landscape',
  DuoLayout.expandedLandscape => 'Expanded landscape',
  DuoLayout.expandedPortrait => 'Expanded portrait',
  DuoLayout.book => 'Book',
  DuoLayout.tabletop => 'Tabletop',
};

String _chromeLayoutLabel(DuoChromeLayout layout) => switch (layout) {
  DuoChromeLayout.topAndBottom => 'Top and bottom',
  DuoChromeLayout.leftRail => 'Left rail',
  DuoChromeLayout.rightRail => 'Right rail',
};

class _Message {
  const _Message(
    this.id,
    this.mailbox,
    this.sender,
    this.subject,
    this.preview,
    this.time,
  );

  final String id;
  final String mailbox;
  final String sender;
  final String subject;
  final String preview;
  final String time;
}
