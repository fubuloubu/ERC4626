import pytest


@pytest.fixture
def sudo(accounts):
    return accounts[-1]


@pytest.fixture
def token(sudo, project):
    return sudo.deploy(project.Token)


@pytest.fixture(params=["VyperVault", "SolidityVault"])
def vault(sudo, token, project, request):
    return sudo.deploy(getattr(project, request.param), token)
