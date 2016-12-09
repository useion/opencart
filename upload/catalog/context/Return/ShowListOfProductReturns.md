# Use case Show List of Product Returns

## Actors

Customer

## Main scenario

1. Customer requests to show list of product returns
2. System lists the product returns

## Extension points

Extension point "showing returns" in step "2."

# Code

## controller/account/return.php

```php
<?php
class ControllerAccountReturn extends Controller {
	private $error = array();

	public function index() {
		if (!$this->customer->isLogged()) {
			$this->session->data['redirect'] = $this->url->link('account/return', '', true);

			$this->response->redirect($this->url->link('account/login', '', true));
		}

		$this->load->language('account/return');

		$this->document->setTitle($this->language->get('heading_title'));

		$data['breadcrumbs'] = array();

		$data['breadcrumbs'][] = array(
			'text' => $this->language->get('text_home'),
			'href' => $this->url->link('common/home')
		);

		$data['breadcrumbs'][] = array(
			'text' => $this->language->get('text_account'),
			'href' => $this->url->link('account/account', '', true)
		);

		$url = '';

		if (isset($this->request->get['page'])) {
			$url .= '&page=' . $this->request->get['page'];
		}

		$data['breadcrumbs'][] = array(
			'text' => $this->language->get('heading_title'),
			'href' => $this->url->link('account/return', $url, true)
		);

		$data['heading_title'] = $this->language->get('heading_title');

		$data['text_empty'] = $this->language->get('text_empty');

		$data['column_return_id'] = $this->language->get('column_return_id');
		$data['column_order_id'] = $this->language->get('column_order_id');
		$data['column_status'] = $this->language->get('column_status');
		$data['column_date_added'] = $this->language->get('column_date_added');
		$data['column_customer'] = $this->language->get('column_customer');

		$data['button_view'] = $this->language->get('button_view');
		$data['button_continue'] = $this->language->get('button_continue');

		$this->load->model('account/return');

		if (isset($this->request->get['page'])) {
			$page = $this->request->get['page'];
		} else {
			$page = 1;
		}

		$data['returns'] = array();

		$return_total = $this->model_account_return->getTotalReturns();

		$results = $this->model_account_return->getReturns(($page - 1) * 10, 10);

		foreach ($results as $result) {
			$data['returns'][] = array(
				'return_id'  => $result['return_id'],
				'order_id'   => $result['order_id'],
				'name'       => $result['firstname'] . ' ' . $result['lastname'],
				'status'     => $result['status'],
				'date_added' => date($this->language->get('date_format_short'), strtotime($result['date_added'])),
				'href'       => $this->url->link('account/return/info', 'return_id=' . $result['return_id'] . $url, true)
			);
		}

		$pagination = new Pagination();
		$pagination->total = $return_total;
		$pagination->page = $page;
		$pagination->limit = $this->config->get($this->config->get('config_theme') . '_product_limit');
		$pagination->url = $this->url->link('account/return', 'page={page}', true);

		$data['pagination'] = $pagination->render();

		$data['results'] = sprintf($this->language->get('text_pagination'), ($return_total) ? (($page - 1) * $this->config->get($this->config->get('config_theme') . '_product_limit')) + 1 : 0, ((($page - 1) * $this->config->get($this->config->get('config_theme') . '_product_limit')) > ($return_total - $this->config->get($this->config->get('config_theme') . '_product_limit'))) ? $return_total : ((($page - 1) * $this->config->get($this->config->get('config_theme') . '_product_limit')) + $this->config->get($this->config->get('config_theme') . '_product_limit')), $return_total, ceil($return_total / $this->config->get($this->config->get('config_theme') . '_product_limit')));

		$data['continue'] = $this->url->link('account/account', '', true);

		$data['column_left'] = $this->load->controller('common/column_left');
		$data['column_right'] = $this->load->controller('common/column_right');
		$data['content_top'] = $this->load->controller('common/content_top');
		$data['content_bottom'] = $this->load->controller('common/content_bottom');
		$data['footer'] = $this->load->controller('common/footer');
		$data['header'] = $this->load->controller('common/header');

		$this->response->setOutput($this->load->view('account/return_list', $data));
	}
}
```

## model/account/return.php

```php
<?php
class ModelAccountReturn extends Model {

	public function getReturns($start = 0, $limit = 20) {
		if ($start < 0) {
			$start = 0;
		}

		if ($limit < 1) {
			$limit = 20;
		}

		$query = $this->db->query("SELECT r.return_id, r.order_id, r.firstname, r.lastname, rs.name as status, r.date_added FROM `" . DB_PREFIX . "return` r LEFT JOIN " . DB_PREFIX . "return_status rs ON (r.return_status_id = rs.return_status_id) WHERE r.customer_id = '" . $this->customer->getId() . "' AND rs.language_id = '" . (int)$this->config->get('config_language_id') . "' ORDER BY r.return_id DESC LIMIT " . (int)$start . "," . (int)$limit);

		return $query->rows;
	}

	public function getTotalReturns() {
		$query = $this->db->query("SELECT COUNT(*) AS total FROM `" . DB_PREFIX . "return`WHERE customer_id = '" . $this->customer->getId() . "'");

		return $query->row['total'];
	}
}
```

## view/theme/default/template/account/return_list.tpl

```php
<?php echo $header; ?>
<div class="container">
  <ul class="breadcrumb">
    <?php foreach ($breadcrumbs as $breadcrumb) { ?>
    <li><a href="<?php echo $breadcrumb['href']; ?>"><?php echo $breadcrumb['text']; ?></a></li>
    <?php } ?>
  </ul>
  <div class="row"><?php echo $column_left; ?>
    <?php if ($column_left && $column_right) { ?>
    <?php $class = 'col-sm-6'; ?>
    <?php } elseif ($column_left || $column_right) { ?>
    <?php $class = 'col-sm-9'; ?>
    <?php } else { ?>
    <?php $class = 'col-sm-12'; ?>
    <?php } ?>
    <div id="content" class="<?php echo $class; ?>"><?php echo $content_top; ?>
      <h1><?php echo $heading_title; ?></h1>
      <?php if ($returns) { ?>
      <div class="table-responsive">
        <table class="table table-bordered table-hover">
          <thead>
            <tr>
              <td class="text-right"><?php echo $column_return_id; ?></td>
              <td class="text-left"><?php echo $column_status; ?></td>
              <td class="text-left"><?php echo $column_date_added; ?></td>
              <td class="text-right"><?php echo $column_order_id; ?></td>
              <td class="text-left"><?php echo $column_customer; ?></td>
              <td></td>
            </tr>
          </thead>
          <tbody>
            <?php foreach ($returns as $return) { ?>
            <tr>
              <td class="text-right">#<?php echo $return['return_id']; ?></td>
              <td class="text-left"><?php echo $return['status']; ?></td>
              <td class="text-left"><?php echo $return['date_added']; ?></td>
              <td class="text-right"><?php echo $return['order_id']; ?></td>
              <td class="text-left"><?php echo $return['name']; ?></td>
              <td class="text-right"><a href="<?php echo $return['href']; ?>" data-toggle="tooltip" title="<?php echo $button_view; ?>" class="btn btn-info"><i class="fa fa-eye"></i></a></td>
            </tr>
            <?php } ?>
          </tbody>
        </table>
      </div>
      <div class="row">
        <div class="col-sm-6 text-left"><?php echo $pagination; ?></div>
        <div class="col-sm-6 text-right"><?php echo $results; ?></div>
      </div>
      <?php } else { ?>
      <p><?php echo $text_empty; ?></p>
      <?php } ?>
      <div class="buttons clearfix">
        <div class="pull-right"><a href="<?php echo $continue; ?>" class="btn btn-primary"><?php echo $button_continue; ?></a></div>
      </div>
      <?php echo $content_bottom; ?></div>
    <?php echo $column_right; ?></div>
</div>
<?php echo $footer; ?>
```


