<!-- vi: set noet ts=2 sw=2 : -->
(function (global, riot, axios) {
	var model = {
		_items: [],

		items: function () {
			return this._items;
		},

		load_items: function () {
			var self = this;
			axios.get('entries')
				.then(function (res) {
					self._items = res.data;
					self.trigger('items_fetched');
				});
		}
	};

	riot.observable(model);

	global.model = model;
})(window, window.riot, window.axios);
