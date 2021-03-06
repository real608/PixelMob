PixelMob.SignoffView = Ember.View.extend(
  willDestroyElement: ->
    clone = this.$().clone()
    this.$().replaceWith(clone)
    clone.slideUp(500, "easeInOutQuad")
  didInsertElement: ->
    this.$().slideUp(0);
    this.$().slideDown(500);
    @get('controller').signOff()
)
