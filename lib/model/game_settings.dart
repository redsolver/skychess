class GameSettings {
  String variant;
  String timeControl;

  GameSettings({
    this.variant = 'standard',
    this.timeControl = 'unlimited',
  });

  Map toJson() => {
        'variant': variant,
        'timeControl': timeControl,
      };
}
