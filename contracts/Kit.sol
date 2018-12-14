pragma solidity ^0.4.24;

import "@aragon/os/contracts/lib/math/SafeMath.sol";

import "@aragon/os/contracts/factory/DAOFactory.sol";
import "@aragon/os/contracts/apm/Repo.sol";
import "@aragon/os/contracts/lib/ens/ENS.sol";
import "@aragon/os/contracts/lib/ens/PublicResolver.sol";
import "@aragon/os/contracts/evmscript/IEVMScriptRegistry.sol"; // needed for EVMSCRIPT_REGISTRY_APP_ID
import "@aragon/os/contracts/apm/APMNamehash.sol";

import "@aragon/apps-shared-minime/contracts/MiniMeToken.sol";
import "@aragon/apps-token-manager/contracts/TokenManager.sol";
import "@aragon/apps-vault/contracts/Vault.sol";
import "@aragon/apps-finance/contracts/Finance.sol";
import "@aragon/apps-voting/contracts/Voting.sol";

import "./Apiary.sol";


contract Kit is APMNamehash, EVMScriptRegistryConstants {
    using SafeMath for uint256;

    uint64 constant PCT = 10 ** 16;
    address constant ANY_ENTITY = address(-1);

    ENS public ens;
    DAOFactory public fac;
    MiniMeTokenFactory tokenFactory;

    event DeployInstance(address dao);
    event InstalledApp(address appProxy, bytes32 appId);

    constructor (ENS _ens) {
        ens = _ens;
        fac = Kit(latestVersionAppBase(apmNamehash("bare-kit"))).fac();
        tokenFactory = new MiniMeTokenFactory();
    }

    function latestVersionAppBase(bytes32 appId) public view returns (address base) {
        Repo repo = Repo(PublicResolver(ens.resolver(appId)).addr(appId));
        (,base,) = repo.getLatest();

        return base;
    }

    function newInstance() public {
        bytes32[5] memory appIds = [
            apmNamehash("voting"),        // 0
            apmNamehash("vault"),         // 1
            apmNamehash("finance"),       // 2
            apmNamehash("token-manager"), // 3
            apmNamehash("apiary")         // 4
        ];

        // Tokens
        MiniMeToken NGT = tokenFactory.createCloneToken(MiniMeToken(address(0)), 0, "Native Governance Token", 0, "NGT", false);
        MiniMeToken ABT = tokenFactory.createCloneToken(MiniMeToken(address(0)), 0, "Apiary Bond Token", 18, "ABT", true);

        NGT.generateTokens(msg.sender, 1);

        // DAO
        Kernel dao = fac.newDAO(this);
        ACL acl = ACL(dao.acl());
        acl.createPermission(this, dao, dao.APP_MANAGER_ROLE(), this);

        // Apps
        Voting metavoting = Voting(
            dao.newAppInstance(
                appIds[0],
                latestVersionAppBase(appIds[0])
            )
        );
        emit InstalledApp(metavoting, appIds[0]);

        Voting voting = Voting(
            dao.newAppInstance(
                appIds[0],
                latestVersionAppBase(appIds[0])
            )
        );
        emit InstalledApp(voting, appIds[0]);

        Vault vault = Vault(
            dao.newAppInstance(
                appIds[1],
                latestVersionAppBase(appIds[1]),
                new bytes(0),
                true
            )
        );
        emit InstalledApp(vault, appIds[1]);

        Finance finance = Finance(
            dao.newAppInstance(
                appIds[2],
                latestVersionAppBase(appIds[2])
            )
        );
        emit InstalledApp(finance, appIds[2]);

        TokenManager tokenManager = TokenManager(
            dao.newAppInstance(
                appIds[3],
                latestVersionAppBase(appIds[3])
            )
        );
        emit InstalledApp(tokenManager, appIds[3]);

        Apiary apiary = Apiary(
            dao.newAppInstance(
                appIds[4],
                latestVersionAppBase(appIds[4])
            )
        );
        emit InstalledApp(apiary, appIds[4]);

        // Votings
        acl.createPermission(ANY_ENTITY, metavoting, metavoting.CREATE_VOTES_ROLE(), metavoting);
        acl.createPermission(ANY_ENTITY, voting, voting.CREATE_VOTES_ROLE(), voting);
        // Vault
        acl.createPermission(finance, vault, vault.TRANSFER_ROLE(), metavoting);
        // Finance
        acl.createPermission(metavoting, finance, finance.CREATE_PAYMENTS_ROLE(), metavoting);
        acl.createPermission(metavoting, finance, finance.EXECUTE_PAYMENTS_ROLE(), metavoting);
        acl.createPermission(metavoting, finance, finance.MANAGE_PAYMENTS_ROLE(), metavoting);
        // Token Manager
        acl.createPermission(metavoting, tokenManager, tokenManager.MINT_ROLE(), metavoting);
        acl.createPermission(metavoting, tokenManager, tokenManager.ISSUE_ROLE(), metavoting);
        acl.createPermission(metavoting, tokenManager, tokenManager.ASSIGN_ROLE(), metavoting);
        acl.createPermission(metavoting, tokenManager, tokenManager.REVOKE_VESTINGS_ROLE(), metavoting);
        acl.createPermission(metavoting, tokenManager, tokenManager.BURN_ROLE(), metavoting);
        // Apiary
        acl.createPermission(ANY_ENTITY, apiary, apiary.BUY_ROLE(), voting);
        acl.createPermission(ANY_ENTITY, apiary, apiary.SELL_ROLE(), voting);
        acl.createPermission(metavoting, apiary, apiary.WITHDRAW_ROLE(), voting);
        acl.createPermission(voting, apiary, apiary.UPDATE_TAP_ROLE(), voting);
        // EVMScriptRegistry
        EVMScriptRegistry reg = EVMScriptRegistry(acl.getEVMScriptRegistry());
        acl.createPermission(metavoting, reg, reg.REGISTRY_ADD_EXECUTOR_ROLE(), metavoting);
        acl.createPermission(metavoting, reg, reg.REGISTRY_MANAGER_ROLE(), metavoting);


        // Initialize apps
        NGT.changeController(tokenManager);
        ABT.changeController(apiary);
        vault.initialize();
        finance.initialize(vault, 30 days);
        tokenManager.initialize(NGT, false, 0);
        apiary.initialize(ABT, finance, uint256(1 ether).div(uint256(24).mul(uint256(3600))), uint32(900000), uint256(100*(10**18)), uint256(200*(10**18)));
        metavoting.initialize(NGT, 50 * PCT, 20 * PCT, 1 days);
        voting.initialize(ABT, 50 * PCT, 20 * PCT, 1 days);

        // Cleanup permissions
        acl.grantPermission(metavoting, dao, dao.APP_MANAGER_ROLE());
        acl.revokePermission(this, dao, dao.APP_MANAGER_ROLE());
        acl.setPermissionManager(metavoting, dao, dao.APP_MANAGER_ROLE());

        acl.grantPermission(metavoting, acl, acl.CREATE_PERMISSIONS_ROLE());
        acl.revokePermission(this, acl, acl.CREATE_PERMISSIONS_ROLE());
        acl.setPermissionManager(metavoting, acl, acl.CREATE_PERMISSIONS_ROLE());

        emit DeployInstance(dao);
    }
}
