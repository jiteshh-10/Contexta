import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom app bar with bookish styling
/// Features: Serif title, back button with tap feedback, optional right action
class ContextaAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final bool showBackButton;
  final Widget? rightAction;
  final bool centerTitle;

  const ContextaAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.showBackButton = true,
    this.rightAction,
    this.centerTitle = false,
  });

  @override
  State<ContextaAppBar> createState() => _ContextaAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}

class _ContextaAppBarState extends State<ContextaAppBar> {
  bool _backPressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.getBorder(context), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Back button
                if (widget.showBackButton && widget.onBack != null)
                  GestureDetector(
                    onTapDown: (_) => setState(() => _backPressed = true),
                    onTapUp: (_) => setState(() => _backPressed = false),
                    onTapCancel: () => setState(() => _backPressed = false),
                    onTap: widget.onBack,
                    child: AnimatedScale(
                      duration: AppTheme.buttonPressDuration,
                      scale: _backPressed ? 0.9 : 1.0,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _backPressed
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                    ),
                  )
                else if (widget.showBackButton)
                  const SizedBox(width: 40), // Placeholder for alignment
                // Spacer for centered title
                if (widget.centerTitle) const Spacer(),

                // Title
                Expanded(
                  flex: widget.centerTitle ? 0 : 1,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: widget.showBackButton ? 8 : 8,
                    ),
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign:
                          widget.centerTitle
                              ? TextAlign.center
                              : TextAlign.left,
                    ),
                  ),
                ),

                // Spacer for centered title
                if (widget.centerTitle) const Spacer(),

                // Right action
                if (widget.rightAction != null)
                  widget.rightAction!
                else
                  const SizedBox(width: 40), // Placeholder for alignment
              ],
            ),
          ),
        ),
      ),
    );
  }
}
