# Use case Change Currency

## Actors

Customer

## Main scenario

1. Customer selects to change the pre-defined currency
2. System shows the available currencies
3. Customer selects the currency
4. System sets the currency

# Code

## view/theme/default/template/common/currency.tpl

```php
<?php if (count($currencies) > 1) { ?>
<div class="pull-left">
<form action="<?php echo $action; ?>" method="post" enctype="multipart/form-data" id="form-currency">
  <div class="btn-group">
    <button class="btn btn-link dropdown-toggle" data-toggle="dropdown">
    <?php foreach ($currencies as $currency) { ?>
    <?php if ($currency['symbol_left'] && $currency['code'] == $code) { ?>
    <strong><?php echo $currency['symbol_left']; ?></strong>
    <?php } elseif ($currency['symbol_right'] && $currency['code'] == $code) { ?>
    <strong><?php echo $currency['symbol_right']; ?></strong>
    <?php } ?>
    <?php } ?>
    <span class="hidden-xs hidden-sm hidden-md"><?php echo $text_currency; ?></span> <i class="fa fa-caret-down"></i></button>
    <ul class="dropdown-menu">
      <?php foreach ($currencies as $currency) { ?>
      <?php if ($currency['symbol_left']) { ?>
      <li><button class="currency-select btn btn-link btn-block" type="button" name="<?php echo $currency['code']; ?>"><?php echo $currency['symbol_left']; ?> <?php echo $currency['title']; ?></button></li>
      <?php } else { ?>
      <li><button class="currency-select btn btn-link btn-block" type="button" name="<?php echo $currency['code']; ?>"><?php echo $currency['symbol_right']; ?> <?php echo $currency['title']; ?></button></li>
      <?php } ?>
      <?php } ?>
    </ul>
  </div>
  <input type="hidden" name="code" value="" />
  <input type="hidden" name="redirect" value="<?php echo $redirect; ?>" />
</form>
</div>
<?php } ?>
```

## controller/common/currency.php

```php
<?php
class ControllerCommonCurrency extends Controller {
	public function index() {
		$this->load->language('common/currency');

		$data['text_currency'] = $this->language->get('text_currency');

		$data['action'] = $this->url->link('common/currency/currency', '', $this->request->server['HTTPS']);

		$data['code'] = $this->session->data['currency'];

		$this->load->model('localisation/currency');

		$data['currencies'] = array();

		$results = $this->model_localisation_currency->getCurrencies();

		foreach ($results as $result) {
			if ($result['status']) {
				$data['currencies'][] = array(
					'title'        => $result['title'],
					'code'         => $result['code'],
					'symbol_left'  => $result['symbol_left'],
					'symbol_right' => $result['symbol_right']
				);
			}
		}

		if (!isset($this->request->get['route'])) {
			$data['redirect'] = $this->url->link('common/home');
		} else {
			$url_data = $this->request->get;

			unset($url_data['_route_']);

			$route = $url_data['route'];

			unset($url_data['route']);

			$url = '';

			if ($url_data) {
				$url = '&' . urldecode(http_build_query($url_data, '', '&'));
			}

			$data['redirect'] = $this->url->link($route, $url, $this->request->server['HTTPS']);
		}

		return $this->load->view('common/currency', $data);
	}

	public function currency() {
		if (isset($this->request->post['code'])) {
			$this->session->data['currency'] = $this->request->post['code'];
		
			unset($this->session->data['shipping_method']);
			unset($this->session->data['shipping_methods']);
		}
		
		if (isset($this->request->post['redirect'])) {
			$this->response->redirect($this->request->post['redirect']);
		} else {
			$this->response->redirect($this->url->link('common/home'));
		}
	}
}
```

## model/localisation/currency.php

```php
<?php
class ModelLocalisationCurrency extends Model {
	public function getCurrencies() {
		$currency_data = $this->cache->get('currency');

		if (!$currency_data) {
			$currency_data = array();

			$query = $this->db->query("SELECT * FROM " . DB_PREFIX . "currency ORDER BY title ASC");

			foreach ($query->rows as $result) {
				$currency_data[$result['code']] = array(
					'currency_id'   => $result['currency_id'],
					'title'         => $result['title'],
					'code'          => $result['code'],
					'symbol_left'   => $result['symbol_left'],
					'symbol_right'  => $result['symbol_right'],
					'decimal_place' => $result['decimal_place'],
					'value'         => $result['value'],
					'status'        => $result['status'],
					'date_modified' => $result['date_modified']
				);
			}

			$this->cache->set('currency', $currency_data);
		}

		return $currency_data;
	}
}
```


