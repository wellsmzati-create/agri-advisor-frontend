import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../web_theme.dart';

// ─── Stat Card ───────────────────────────────────────────────────────────────
class WebStatCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final Gradient gradient;
  final String? trend;
  final bool trendUp;

  const WebStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.trend,
    this.trendUp = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              if (trend != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(trendUp ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 11),
                        const SizedBox(width: 3),
                        Flexible(child: Text(trend!, style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(title, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
          Text(subtitle, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 10), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────
class WebCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final String? title;
  final Widget? titleAction;

  const WebCard({super.key, required this.child, this.padding, this.title, this.titleAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WebColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WebColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            LayoutBuilder(
              builder: (context, constraints) {
                final stackHeader =
                    titleAction != null && constraints.maxWidth < 520;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                  child: stackHeader
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title!,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: WebColors.textPrimary,
                              ),
                            ),
                            if (titleAction != null) ...[
                              const SizedBox(height: 8),
                              titleAction!,
                            ],
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title!,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: WebColors.textPrimary,
                                ),
                              ),
                            ),
                            if (titleAction != null) ...[
                              const SizedBox(width: 12),
                              Flexible(child: titleAction!),
                            ],
                          ],
                        ),
                );
              },
            ),
          if (title != null) const SizedBox(height: 4),
          Padding(padding: padding ?? const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class WebBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const WebBadge({super.key, required this.label, required this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: filled ? Colors.white : color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────
class WebAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? color;
  final Gradient? gradient;

  const WebAvatar({super.key, required this.initials, this.size = 36, this.color, this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gradient == null ? (color ?? WebColors.primary) : null,
        gradient: gradient,
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: size * 0.33,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────
class WebPageHeader extends StatelessWidget {
  final String title, subtitle;
  final Widget? action;

  const WebPageHeader({super.key, required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeader = action != null && constraints.maxWidth < 760;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: WebColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: WebColors.textSecondary,
              ),
            ),
          ],
        );

        if (stackHeader) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              if (action != null) ...[
                const SizedBox(height: 14),
                action!,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            if (action != null) ...[
              const SizedBox(width: 16),
              Flexible(child: action!),
            ],
          ],
        );
      },
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────
class WebSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;

  const WebSearchBar({super.key, required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 13, color: WebColors.textMuted),
          prefixIcon: const Icon(Icons.search, size: 18, color: WebColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: WebColors.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: WebColors.divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: WebColors.primary, width: 1.5)),
          filled: true,
          fillColor: WebColors.cardBg,
        ),
      ),
    );
  }
}

// ─── Web Button ───────────────────────────────────────────────────────────────
class WebButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool outlined;
  final Color? color;

  const WebButton({super.key, required this.label, this.icon, this.onPressed, this.outlined = false, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? WebColors.primary;
    return SizedBox(
      height: 38,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: c,
                side: BorderSide(color: c),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: c,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
    );
  }
}

// ─── Data Table Wrapper ───────────────────────────────────────────────────────
class WebDataTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;

  const WebDataTable({super.key, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(bottom: BorderSide(color: WebColors.divider)),
          ),
          child: Row(
            children: columns.map((c) => Expanded(
              child: Text(c, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: WebColors.textSecondary, letterSpacing: 0.5)),
            )).toList(),
          ),
        ),
        ...rows.asMap().entries.map((e) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: e.key.isEven ? Colors.white : const Color(0xFFFAFBFC),
            border: const Border(bottom: BorderSide(color: WebColors.divider)),
          ),
          child: Row(children: e.value.map((w) => Expanded(child: w)).toList()),
        )),
      ],
    );
  }
}

// ─── Activity Item ────────────────────────────────────────────────────────────
class WebActivityItem extends StatelessWidget {
  final String time, action, farmer, detail, icon;
  final Color color;
  final bool isLast;

  const WebActivityItem({
    super.key,
    required this.time,
    required this.action,
    required this.farmer,
    required this.detail,
    required this.icon,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 16))),
              ),
              if (!isLast)
                Expanded(child: Container(width: 1.5, color: WebColors.divider, margin: const EdgeInsets.symmetric(vertical: 4))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          action,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: WebColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: WebColors.textMuted,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('$farmer • $detail', style: GoogleFonts.inter(fontSize: 12, color: WebColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Field (read-only display) ──────────────────────────────────────────
class WebInfoField extends StatelessWidget {
  final String label, value;
  final IconData? icon;

  const WebInfoField({super.key, required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: WebColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: WebColors.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    icon,
                    size: 14,
                    color: WebColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: WebColors.textPrimary,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
