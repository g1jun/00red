



<div id="donate_module">
<div id="donate_board" class="donate_bar center">

    <a id="btn_donate" class="btn_donate" target="_self" href="javascript:;" title="打赏"></a>

    <span class="donate_txt">  
      {% if theme.donate.text %}
            {{ theme.donate.text }}
      {% endif %} 
    </span>

</div>

<div id="donate_guide" class="donate_bar center hidden">

    {% if theme.donate.wechat %}
      <a href="{{ theme.donate.wechat }}" title="微信扫一扫" rel="article0" style="float:left">
      <img src="{{ theme.donate.wechat }}" title="微信"/>
      </a>
    {% endif %}  
          
   {% if theme.donate.alipay %}
      <a href="{{ theme.donate.alipay }}" title="支付宝扫一扫" rel="article0" style="float:right">
      <img src="{{ theme.donate.alipay }}" title="支付宝"/>
      </a 
    {% endif %}

</div>

<script type="text/javascript">
    document.getElementById('btn_donate').onclick = function() {
      $('#donate_board').addClass('hidden');
      $('#donate_guide').removeClass('hidden');
    }
</script>



</div>
