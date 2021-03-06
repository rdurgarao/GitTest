require 'spec_helper'

RSpec.describe Payment::PaypalController, :type => :controller do
  before do
    sign_in create(:user)
  end

  describe '#begin', :vcr do
    context 'when not provides order_no' do
      it 'creates order from session and redirect to PayPal' do
        CurrencyType.create(name: 'USD', code: 'USD', rate: 30)
        post :begin, {locale: 'zh-TW'}, { cart: cart_session }
        order = Order.last
        expect(order).to be_pending
        expect(order.payment_id).to be_present
        expect(response.status).to eq(302)
      end
    end

    context 'when provides order_no' do
      context 'and order is pending' do
        it 'pays the order and redirect to finish path', :vcr do
          order = create(:pending_order, :priced, payment_method: 'paypal')
          post :begin, locale: 'zh-TW', order_no: order.order_no
          expect(order.reload).to be_pending
          expect(order.payment_id).to be_present
          expect(response.status).to eq(302)
        end
      end

      context 'and order is not pending' do
        it 'raises not found' do
          order = create(:paid_order, payment_method: 'paypal')
          post :begin, locale: 'zh-TW', order_no: order.order_no
          expect(response.status).to eq(404)
        end
      end

      context 'and order is not found' do
        it 'raises not found' do
          post :begin, locale: 'zh-TW', order_no: 'ABCDENDGG'
          expect(response.status).to eq(404)
        end
      end
    end

    context 'free checking' do
      it 'with coupon discount all order price' do
        post :begin, {locale: 'zh-TW'}, { cart: cart_session_for_free_checking }
        order = Order.last
        expect(order).to be_paid
        expect(response.session['cart']).to be nil
        expect(response).to redirect_to(order_result_path(order.order_no))
      end
    end
  end

  describe '#callback', :vcr do
    before do
      CurrencyType.create(name: 'USD', code: 'USD', rate: 30)
      CurrencyType.create(name: 'TWD', code: 'TWD', rate: 1)
    end

    let(:order) {
      post :begin, {locale: 'zh-TW'}, { cart: cart_session }
      Order.last
    }

    context 'when payment is approved' do
      it 'pays the order and redirect to finish path' do
        allow_any_instance_of(PayPal::SDK::REST::Payment).to receive(:state).and_return('approved')
        get :callback, locale: 'zh-TW', order_no: order.order_no, PayerID: '0'
        expect(order.reload).to be_paid
        expect(response).to redirect_to(finish_payment_paypal_path(order_no: order.order_no))
      end
    end

    context 'when payment is not approved' do
      it 'renders errors' do
        allow_any_instance_of(PayPal::SDK::REST::Payment).to receive(:state).and_return('get fucked')
        get :callback, locale: 'zh-TW', order_no: order.order_no, PayerID: '0'
        expect(order.reload).not_to be_paid
        expect(response.status).to eq(302)
      end
    end
  end

  describe '#finish' do
    it 'redirect to order result page' do
      order = create(:paid_order, payment_method: 'paypal')
      get :finish, locale: 'zh-TW', order_no: order.order_no
      expect(response).to redirect_to(order_result_path(order.order_no))
    end
  end

  def cart_session
    work = create(:work)
    {
      currency: 'USD',
      payment: 'paypal',
      billing_info: {
        country_code: 'TW',
        email: 'ayaya@commandp.me',
        phone: '0228825252',
        address: 'Ayaya Home'
      },
      items: [[work.to_gid.to_s, 1]]
    }
  end

  def cart_session_for_free_checking
    work = create(:work)
    coupon = create(:max_price_coupon)
    {
      currency: 'USD',
      coupon_code: coupon.code,
      payment: 'paypal',
      billing_info: {
        country_code: 'TW',
        email: 'ayaya@commandp.me',
        phone: '0228825252',
        address: 'Ayaya Home'
      },
      items: [[work.to_gid.to_s, 1]]
    }
  end
end
