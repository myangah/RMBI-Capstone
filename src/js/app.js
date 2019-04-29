App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',
  hasVoted: false,

  init: function() {
    return App.initWeb3();
  },

  initWeb3: function() {
    // TODO: refactor conditional
    if (typeof web3 !== 'undefined') {
      // If a web3 instance is already provided by Meta Mask.
      App.web3Provider = web3.currentProvider;
      web3 = new Web3(web3.currentProvider);
    } else {
      // Specify default instance if no web3 instance provided
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
      web3 = new Web3(App.web3Provider);
    }
    return App.initContract();
  },

  initContract: function() {
    $.getJSON("CrowdFunding.json", function(crowdfunding) {
      // Instantiate a new truffle contract from the artifact
      App.contracts.CrowdFunding = TruffleContract(crowdfunding);
      // Connect provider to interact with contract
      App.contracts.CrowdFunding.setProvider(App.web3Provider);

      // App.listenForEvents();

      return App.render();
    });
  },

  // Listen for events emitted from the contract
  
  // listenForEvents: function() {
  //   App.contracts.Election.deployed().then(function(instance) {
  //     // Restart Chrome if you are unable to receive this event
  //     // This is a known issue with Metamask
  //     // https://github.com/MetaMask/metamask-extension/issues/2393
  //     instance.votedEvent({}, {
  //       fromBlock: 0,
  //       toBlock: 'latest'
  //     }).watch(function(error, event) {
  //       console.log("event triggered", event)
  //       // Reload when a new vote is recorded
  //       App.render();
  //     });
  //   });
  // },

  render: function() {
    //var electionInstance;
    var CFInstance;
    var loader = $("#loader");
    var content = $("#content");
    
    loader.show();
    content.hide();

    // Load account data
    web3.eth.getCoinbase(function(err, account) {
      if (err === null) {
        App.account = account;
        $("#accountAddress").html("Your Account: " + account);
      }
    });

    // Test coding
    App.contracts.CrowdFunding.deployed().then(function(i) {
      CFInstance = i;
      console.log(i)
      return CFInstance.AccountCount();
    }).then(function(AccountCountNum) {
      

      var AccountCount = $("#AccountCount");
      AccountCount.empty();

      var amountSelect = $('#amountSelect');
      amountSelect.empty();

      amountSelect.append("<option value='" + 100 + "' >" + 100 + "</ option>")

      // var id;
      // var name;
      // var Amount;
      for (var i =1; i <= AccountCountNum; i++){
        CFInstance.addressCount(i).then(function(Account) { 
          CFInstance.Accounts(Account).then(function(t){
            console.log(1)
            var id = t[0];
            console.log(id);
            var name = t[1];
            var Amount = t[4];
            var TranCount = t[2];
            var DefaultCount = t[3];
            var Rating = t[5]/1000;
            var minRating = t[7]/1000;
            var Status = t[8];
            AccountCount.append("<tr><th>" + id + "</th><td>" + name + "</td><td>" + Amount + "</td><td>" + TranCount + "</td><td>" + DefaultCount + "</td><td>" + Rating + "</td><td>" + minRating + "</td><td>" + Status + "</td></tr>");

          })
        });
      }
      // CFInstance.Transactions(1).then(function(t) { 
      //   console.log(t)
      //   var id = t[0];
      //   console.log(id)
      //   var name = t[1];
      //   var Amount = t[2];
      //   AccountCount.append("<tr><th>" + id + "</th><td>" + name + "</td><td>" + Amount + "</td></tr>");
      // });
      
      //console.log(CFInstance.AccountCount(1)
      

    })
    loader.hide();
    content.show();
  },
  ApplyFund: function() {
    var amountSelect = $('#amountSelect').val();
    App.contracts.CrowdFunding.deployed().then(function(instance) {
      console.log(instance)
      console.log(App.account)
      return instance.applyFund(App.account, amountSelect, { from: App.account });
    }).then(function(result) {
      // Wait for votes to update
      $("#content").hide();
      $("#loader").show();
    }).catch(function(err) {
      console.error(err);
    });
  }
}


    

    // Load contract data
    // App.contracts.Election.deployed().then(function(instance) {
    //   electionInstance = instance;
    //   return electionInstance.candidatesCount();
    // }).then(function(candidatesCount) {
    //   var candidatesResults = $("#candidatesResults");
    //   candidatesResults.empty();

    //   var candidatesSelect = $('#candidatesSelect');
    //   candidatesSelect.empty();

    //   for (var i = 1; i <= candidatesCount; i++) {
    //     electionInstance.candidates(i).then(function(candidate) {
    //       var id = candidate[0];
    //       var name = candidate[1];
    //       var voteCount = candidate[2];

    //       // Render candidate Result
    //       var candidateTemplate = "<tr><th>" + id + "</th><td>" + name + "</td><td>" + voteCount + "</td></tr>"
    //       candidatesResults.append(candidateTemplate);

    //       // Render candidate ballot option
    //       var candidateOption = "<option value='" + id + "' >" + name + "</ option>"
    //       candidatesSelect.append(candidateOption);
    //     });
    //   }
    //   return electionInstance.voters(App.account);
    // }).then(function(hasVoted) {
    //   // Do not allow a user to vote
    //   if(hasVoted) {
    //     $('form').hide();
    //   }
    //   loader.hide();
    //   content.show();
    // }).catch(function(error) {
    //   console.warn(error);
    // });
  // },

//   castVote: function() {
//     var candidateId = $('#candidatesSelect').val();
//     App.contracts.Election.deployed().then(function(instance) {
//       return instance.vote(candidateId, { from: App.account });
//     }).then(function(result) {
//       // Wait for votes to update
//       $("#content").hide();
//       $("#loader").show();
//     }).catch(function(err) {
//       console.error(err);
//     });
//   }
// };

$(function() {
  $(window).load(function() {
    App.init();
  });
});
