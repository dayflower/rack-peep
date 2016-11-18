<!-- vi: set ft=html nu noet ts=2 sw=2 : -->
<app>
	<h1 class="c-heading">Rack::Peep</h1>

	<div class="o-grid">
		<div class="o-grid__cell">
			<button class="c-button c-button--info" onclick="{on_reload_clicked}">Reload</button>
		</div>
	</div>

	<div class="o-grid">
		<div class="o-grid__cell">
			<table class="c-table c-table--clickable c-table--condensed">
				<thead class="c-table__head">
					<tr class="c-table__row c-table__row--heading">
						<th class="c-table__cell">Method</th>
						<th class="c-table__cell">URL</th>
						<th class="c-table__cell">Status</th>
						<th class="c-table__cell">Timestamp</th>
					</tr>
				</thead>
				<tbody class="c-table__body">
					<tr class="c-table__row {parent.cursor == id ? 'u-bg-yellow-light' : ''}" each="{entries}" onclick="{on_entry_clicked}">
						<td class="c-table__cell">{req.method}</td>
						<td class="c-table__cell">{req.fullpath}</td>
						<td class="c-table__cell">{res.status}</td>
						<td class="c-table__cell">{timestamp}</td>
					</tr>
				</tbody>
			</table>
		</div>
	</div>

	<div class="o-grid" show="{entry}" style="margin-top: 1em;">
		<div class="o-grid__cell">
			<div class="c-card u-high">
				<header class="c-card__header u-bg-brand u-color-white" style="padding-bottom: 0.5em;">
					<h2 class="c-heading">Request</h2>
				</header>
				<div class="c-card__item c-card__item--divider">Headers</div>
				<div class="c-card__item u-bg-beige">
					<ul class="c-list c-list--unstyled" each="{ field, value in entry.req.headers }">
						<li class="c-list__item">
							<strong>{field}:</strong> {value}
						</li>
					</ul>
				</div>
				<div class="c-card__item c-card__item--divider" show="{entry.req.query_string}">Query</div>
				<div class="c-card__item" show="{entry.req.query_string}">
					<ul class="c-list c-list--unstyled" each="{ field, value in entry.req.query }">
						<li class="c-list__item">
							<strong>{field}:</strong> {value}
						</li>
					</ul>
				</div>
				<div class="c-card__item c-card__item--divider" show="{entry.req.body}">Body</div>
				<div class="c-card__item" show="{entry.req.body}">
					<pre>{ entry.req.body }</pre>
				</div>
			</div>
		</div>

		<div class="o-grid__cell" hide="{res_hidden}">
			<div class="c-card u-high">
				<header class="c-card__header u-bg-brand u-color-white" style="padding-bottom: 0.5em;">
					<button type="button" class="c-button c-button--close" style="font-family: Arial; right: 1.5em;" onclick="{on_res_close_button_clicked}">x</button>
					<h2 class="c-heading">Response</h2>
				</header>
				<div class="c-card__item c-card__item--divider">Status</div>
				<div class="c-card__item u-bg-beige">{entry.res.status}</div>
				<div class="c-card__item c-card__item--divider">Headers</div>
				<div class="c-card__item u-bg-beige">
					<ul class="c-list c-list--unstyled" each="{ field, value in entry.res.headers }">
						<li class="c-list__item">
							<strong>{field}:</strong> {value}
						</li>
					</ul>
				</div>
				<div class="c-card__item c-card__item--divider" show="{entry.res.body}">Body</div>
				<div class="c-card__item" show="{entry.res.body}">
					<pre>{ entry.res.body }</pre>
				</div>
			</div>
		</div>
	</div>

	<script>
		var self = this;

		on_entry_clicked(e) {
			this.entry = e.item;
			this.res_hidden = false;
			this.cursor = e.item.id;
		}

		on_reload_clicked(e) {
			this.opts.model.load_items();
		}

		on_res_close_button_clicked() {
			this.res_hidden = true;
		}

		this.opts.model.on('items_fetched', function () {
			self.entry = null;
			self.cursor = null;
			self.update({ entries: self.opts.model.items() });
		});

		this.opts.model.load_items();
	</script>
</app>
