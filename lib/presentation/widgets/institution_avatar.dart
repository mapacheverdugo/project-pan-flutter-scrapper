import 'package:cached_network_svg_image/cached_network_svg_image.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/entities/institution.dart';

class InstitutionAvatar extends StatelessWidget {
  const InstitutionAvatar._({
    required this.institution,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Institution? institution;

  factory InstitutionAvatar({
    required Institution institution,
    double width = 40,
    double height = 40,
    BorderRadius? borderRadius,
  }) {
    return InstitutionAvatar._(
      institution: institution,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  factory InstitutionAvatar.empty({
    double width = 40,
    double height = 40,
    BorderRadius? borderRadius,
  }) {
    return InstitutionAvatar._(
      institution: null,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  String? get iconUrl => institution != null
      ? switch (institution!.suggestedIconOnMainColor) {
          'iconPositive' => institution!.iconPositiveUrl ?? '',
          'iconAlt' => institution!.iconAltUrl ?? '',
          _ => institution!.iconNegativeUrl,
        }
      : null;

  bool? get isIconNegative => iconUrl == institution?.iconNegativeUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: institution?.mainColor ?? Colors.grey,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: iconUrl != null
          ? CachedNetworkSVGImage(
              iconUrl ?? '',
              colorFilter: isIconNegative ?? false
                  ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                  : null,
            )
          : Icon(
              Icons.account_balance,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
    );
  }
}
