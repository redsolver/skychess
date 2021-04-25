import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skychess/app.dart';
import 'package:skychess/util/skylink.dart';
import 'package:skychess/widget/username_widget.dart';
import 'package:skynet/src/skystandards/profile.dart';
import 'package:collection/collection.dart';

class UserWidget extends StatelessWidget {
  final String userId;

  UserWidget(this.userId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile>(future: () async {
      final profile = await mySkyService.profileDAC.getProfile(userId);

      if (profile == null)
        return Profile(
          username: 'No profile set',
          location: 'Click to edit',
          topics: ['###'],
          version: 1,
        );

      return profile;
    }(), builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Shimmer.fromColors(
            baseColor:
                snapshot.hasError ? Colors.red.shade800 : SkyColors.grey4,
            highlightColor:
                snapshot.hasError ? Colors.red.shade800 : SkyColors.follow,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 8),
                ClipRRect(
                  borderRadius: borderRadius,
                  child: Container(
                    height: 48,
                    width: 48,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  width: 8,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 12.0,
                      width: 72,
                      color: Colors.white,
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Container(
                      height: 10.0,
                      width: 56,
                      color: Colors.white,
                    ),
                  ],
                ),
                SizedBox(
                  width: 8,
                ),
              ],
            ));
      }
      final profile = snapshot.data;
      return Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: userId == null
              ? null
              : () {
                  context.beamToNamed('/user/$userId');
                },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: borderRadius,
                child: CachedNetworkImage(
                  imageUrl: resolveSkylink(
                    (profile.avatar ?? []).firstOrNull?.url ??
                        'sia://CABdyKgcVLkjdsa0HIjBfNicRv0pqU7YL-tgrfCo23DmWw',
                  ),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(
                width: 8,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildUsernameWidget(userId, profile, context, bold: true),
                  SizedBox(
                    height: 2,
                  ),
                  Text(
                    profile.location ?? '',
                    style: TextStyle(fontSize: 12), // TODO check
                  ),
                ],
              ),
              SizedBox(
                width: 8,
              ),
            ],
          ),
        ),
      );
    });
  }
}
